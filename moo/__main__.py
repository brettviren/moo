#!/usr/bin/env python3
'''
Main CLI to moo
'''
import os
import re
import json
import click
import moo
from pprint import pprint, pformat


class Context:
    '''
    Application context collects parameters and methods common to commands.
    '''
    def __init__(self, dpath="", mpath=(), tpath=(),
                 tla=(), transform=(), graft=()):
        # use substructure at this data object path
        self.dpath = dpath 
        # search path for models (data)
        self.mpath = moo.util.existing_paths(mpath, True) 
        # search path for templates
        self.tpath = moo.util.existing_paths(tpath, True) 
        self.tlas = dict() # top level arguments
        if tla:
            self.tlas = moo.util.tla_pack(tla, mpath)
        self.transforms = transform
        self.grafts = graft

    def just_load(self, filename, dpath=None):
        '''
        Simple load with path search and dpath reduction
        '''
        return moo.io.load(self.resolve(filename),
                           self.search_path(filename),
                           dpath or self.dpath, **self.tlas)

    def load(self, filename, dpath=None):
        '''
        Load a data structure from a file.

        Search mpath for file and return substructure at dpath.
        '''
        model = self.just_load(filename, dpath)
        model = self.graft(model)
        model = self.transform(model)
        return model

    def graft(self, model):
        'Apply any grafts to the model'
        for g in self.grafts:
            ptr, fname = moo.util.parse_ptr_spec(g)
            data = self.just_load(fname)
            model = moo.util.graft(model, ptr, data)
        return model

    def transform(self, model, transforms=()):
        'Transform a model'
        if self.transforms:
            model = moo.util.transform(model, transforms + self.transforms)
        return model

    def search_path(self, fname):
        '''
        Return search path for given file name or extension
        '''
        if fname.endswith('j2'):
            return moo.util.search_path(fname, self.tpath)
        return moo.util.search_path(fname, self.mpath)

    def resolve(self, filename):
        '''
        Resolve a filename to absolute path.
        '''
        ret = None

        ret = moo.util.resolve(filename, self.search_path(filename))
        if ret is None:
            raise RuntimeError(f'can not resolve {filename}')
        return ret

    def render(self, templ_file, model = None):
        '''
        Render a template in templ_file.

        If model is given provide its data to the template.
        '''
        templ = self.resolve(templ_file)
        helper = self.just_load("moo.jsonnet", dpath="templ")
        # this provides the variables that the template sees:
        params = dict(moo=helper)
        if model:
            params['model'] = model
        tpath = self.search_path(templ_file)
        return moo.templates.render(templ, params, tpath)

    def imports(self, filename):
        '''
        Return list of files the given file imports
        '''
        filename = self.resolve(filename)
        if filename.endswith('.j2'):
            fpath = self.tpath
        else:
            fpath = self.mpath
        return moo.imports(filename, fpath, **self.tlas)

    def save(self, filename, data):
        '''Save data to named file.  If intermediate path is missing, it will
        be created.
        '''
        absdir = os.path.dirname(os.path.realpath(filename))
        if not os.path.exists(absdir):
            os.makedirs(absdir)
        dotext = os.path.splitext(filename)[-1]
        if isinstance(data, str):
            data = data.encode()
        with open(filename, 'wb') as fp:
            fp.write(data)
            

@click.group()
@click.option('-D', '--dpath', default="",
              help="Specify a selection path into the model data structure")
@click.option('-M', '--mpath', envvar='MOO_LOAD_PATH', multiple=True,
              type=click.Path(exists=False, dir_okay=True, file_okay=False),
              help="Add directory to data file search paths (can use MOO_LOAD_PATH env var)")
@click.option('-T', '--tpath', envvar='MOO_TEMPLATE_PATH', multiple=True,
              type=click.Path(exists=False, dir_okay=True, file_okay=False),
              help="Add directory to template file search paths (can use_TEMPLATE_PATH env var)")
@click.option('-A', '--tla', multiple=True,
              help="Specify a 'top-level argument' to a functional model as a var=string or var=file.jsonnet")
@click.option('-g', '--graft', multiple=True, type=str,
              help="Graft a data structure given in a model file into the model in the form: /json/ptr:file.jsonnet")
@click.option('-t', '--transform', multiple=True, type=str,
              help="Specify a model transform")
@click.pass_context
def cli(ctx, dpath, mpath, tpath, tla, graft, transform):
    '''
    moo command line interface
    '''
    ctx.obj = Context(dpath, mpath, tpath, tla, transform, graft)


@cli.command("resolve")
@click.argument('filename')
@click.pass_context
def resolve(ctx, filename):
    '''
    Resolve a filename as moo would internally.
    '''
    try:
        filename = ctx.obj.resolve(filename)
    except ValueError:
        click.echo(f'can not resolve {filename}')
    else:
        click.echo(filename)


@cli.command("path")
@click.argument('filename')
@click.pass_context
def path(ctx, filename):
    '''
    Print search path for representative file or file extension name
    '''
    p = ctx.obj.search_path(filename)
    click.echo('\n'.join(p))


@cli.command("validate")
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.option('-S', '--spath', default="",
              help="Specify path to validation schema object in schema data")
@click.option('-s', '--schema', required=True,
              type=click.Path(exists=True, dir_okay=False, file_okay=True),
              help="JSON Schema to validate against.")
@click.option("--sequence", default=False, is_flag=True,
              help="Assume a sequence of schema and models")
@click.option("--passfail", default=False, is_flag=True,
              help="Print PASS or FAIL instead of null/throw")
@click.option('-V', '--validator', default="jsonschema",
              type=click.Choice(["jsonschema", "fastjsonschema"]),
              help="Specify which validator")
@click.argument('model')
@click.pass_context
def cmd_validate(ctx, output, spath, schema, sequence, passfail, validator, model):
    '''
    Validate a model against a schema
    '''
    sche = ctx.obj.just_load(schema, spath)
    data = ctx.obj.load(model)

    if not sequence:
        data = [data]
        sche = [sche]
    else:
        assert len(data) == len(sche)
    res = list()
    for m, s in zip(data, sche):
        if passfail:
            try:
                one = moo.util.validate(m, s, validator)
            except moo.util.ValidationError:
                res.append("FAIL")
            else:
                res.append("PASS")
        else:
            one = moo.util.validate(m, s, validator)
            res.append(one)
    if not sequence:
        res = res[0]
    text = json.dumps(res, indent=4)
    ctx.obj.save(output, text)


@cli.command("regex")
@click.option('-V', '--validator', default="jsonschema",
              type=click.Choice(["jsonschema", "fastjsonschema"]),
              help="Specify which validator")
@click.option("-O", "--only", default=False, is_flag=True,
              help="Assure regex is bound by ^$")
@click.option('-R', '--rpath', default="",
              help="Specify a data path and treat regex as a file to load")
@click.argument('regex')
@click.argument('string')
@click.pass_context
def cmd_regex(ctx, validator, only, rpath, regex, string):
    '''
    Validate a string against a regex
    '''
    if rpath:
        regex = ctx.obj.just_load(regex, rpath)

    if only:
        if regex[0] != '^':
            regex = '^' + regex
        if regex[-1] != '$':
            regex = regex + '$'

    valid = dict(type="string", pattern=regex)
    res = moo.util.validate(string, valid, validator)
    if res:
        print(regex)
        print(res)


@cli.command("compile")
@click.option('-m', '--multi', default="",
              help="Write multiple output files")
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.option('--string/--no-string', '-S/ ', default=False,
              help="Treat output as string not JSON")
@click.argument('model')
@click.pass_context
def compileit(ctx, multi, output, string, model):
    '''
    Compile a model to JSON
    '''
    data = ctx.obj.load(model)
    if multi:
        os.makedirs(multi, exist_ok=True)
        for one, dat in data.items():
            one = os.path.join(multi, one)
            if not string:
                dat = json.dumps(dat, indent=4)
            ctx.obj.save(one, dat)
    else:
        if not string:
            data = json.dumps(data, indent=4)
        ctx.obj.save(output, data)


@cli.command()
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.option('-f', '--format', default='repr',
              type=click.Choice(['json', 'repr', 'pretty', 'plain', 'types']),
              help="Output format")
@click.argument('model')
@click.pass_context
def dump(ctx, output, format, model):
    '''
    Like render but print model that would be sent to the template
    '''
    data = ctx.obj.load(model)
    if format == 'json':
        print(json.dumps(data, indent=4))
    elif format == 'repr':
        print(repr(data))
    elif format == 'pretty':
        pprint(data)
    elif format == 'types':
        if isinstance(data, list):
            for one in data:
                print(type(one))
        elif isinstance(data, dict):
            for key, val in data.items():
                print(key, type(val))
        else:
            print(type(data))
    else:
        print(data)


@cli.command()
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.argument('model')
@click.argument('templ')
@click.pass_context
def render(ctx, output, model, templ):
    '''
    Render a template against a model.

    An empty model may be given (ie, with "" on shell command line).
    '''
    data = None
    if model:
        data = ctx.obj.load(model)
    text = ctx.obj.render(templ, data)
    ctx.obj.save(output, text)

@cli.command('render-deps')
@click.option('-t', '--target', required=True,
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Name of target in the .d file")
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Dependency output file, default is stdout")
@click.argument('model')
@click.argument('templ')
@click.pass_context
def render_deps(ctx, target, output, model, templ):
    '''Produce a .d dependencies file for the corresponding call to "render"

    Produce a .d dependencies file in the style of `gcc -MD` to be
    used by a build system (Makefile or ninja), corresponding to a
    call to "moo render". The arguments to "moo render-deps" should be
    the same as the arguments to the corresponding call to "moo
    render", with the following exceptions:

    * The -t option to "moo render-deps" is typically taken from the -o option to "moo render"
    * The -o option to "moo render-deps" is the name of the .d file that should be output

    '''
    model_deps = ctx.obj.imports(model)
    templ_deps = ctx.obj.imports(templ)
    deps_string = f'{target}: '
    deps_string += " ".join(templ_deps)
    deps_string += " "
    deps_string += " ".join(model_deps)
    deps_string += "\n"
    ctx.obj.save(output, deps_string)


@cli.command('render-many')
@click.option('-o', '--outdir', default=".",
              type=click.Path(dir_okay=True, file_okay=False),
              help="Output directory, default is '.'")
@click.argument('model')
@click.pass_context
def render_many(ctx, outdir, model):
    '''Render many files for a project.

    The model found at the data path dpath should be a Jsonnet array
    of moo.render() objects.

    '''
    data = ctx.obj.load(model)
    for one in data:
        data = ctx.obj.transform(one["model"], one.get("transform", ()))
        text = ctx.obj.render(one["template"], data)
        output = os.path.join(outdir, one["filename"])
        print(f"generating {output}:")
        odir = os.path.dirname(output)
        if not os.path.exists(odir):
            os.makedirs(odir)
        ctx.obj.save(output, text)


@cli.command()
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.argument('filename')
@click.pass_context
def imports(ctx, output, filename):
    '''
    Emit a list of imports required by the model
    '''
    deps = ctx.obj.imports(filename)
    if output.endswith(".cmake"):  # special output format, cmake
        basename = os.path.splitext(os.path.basename(output))[0]
        varname = re.sub("[^a-zA-Z0-9]", "_", basename).upper()
        lines = [f'set({varname}']
        lines += ['    "%s"' % one for one in deps]
        lines += [')']
        text = '\n'.join(lines)
    else:
        text = '\n'.join(deps)
    ctx.obj.save(output, text)


@cli.command()
def version():
    'Print the version'
    click.echo(moo.__version__)


def main():
    cli(obj=None)


if '__main__' == __name__:
    main()

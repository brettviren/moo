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
        '''
        A CLI context

        - dpath :: data path to sub-structure to use
        - mpath :: file paths to search for models
        - tpath :: file paths to search for templates
        - tla :: Jsonnet top level arguments
        - transform :: transformations to apply
        - graph :: data to graft on to model
        '''

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
        Simple load with path search and dpath reduction.

        Filename may be prefixed as dpath:filename to use that dpath instead of the one passed.
        '''
        dpath, filename = moo.util.unprefix(filename, dpath)
        return moo.io.load(self.resolve(filename),
                           self.search_path(filename),
                           dpath or self.dpath, **self.tlas)

    def load(self, filename, dpath=None):
        '''
        Load a data structure from a file.

        Search mpath for file and return substructure at dpath.

        Filename may be prefixed as dpath:filename to use that dpath instead of the one passed.
        '''
        dpath, filename = moo.util.unprefix(filename, dpath)
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
        Return list of files the given file imports.
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
            

cmddef = dict(context_settings = dict(help_option_names=['-h', '--help']))

@click.group(**cmddef)
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
    if '.' not in filename:
        filename = 'test.' + filename
    p = ctx.obj.search_path(filename)
    click.echo('\n'.join(p))


@cli.command("validate")
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.option('-s', '--schema', type=str,
              help="File containing a representation of a schema.")
@click.option('-t', '--target', default=None, multiple=True,
              help="Specify target schema of the model")
@click.option("--sequence", default=False, is_flag=True,
              help="Indicate the model is a sequence of models (ie, not an array model)")
@click.option("--passfail", default=False, is_flag=True,
              help="Print PASS or FAIL instead of null/throw")
@click.option('-V', '--validator', default="jsonschema",
              type=click.Choice(["jsonschema", "fastjsonschema"]),
              help="Specify which validator")
@click.argument('model')
@click.pass_context
def cmd_validate(ctx, output, schema, target, sequence, passfail, validator, model):
    '''
    Validate models against target schema.

    A full "context" schema must be provided by -s/--schema if it is required for target schema to resolve any dependencies.  The "context" schema is identified with a string of the form "filename with optional dataprefix".

        -s myschema.subschema:my-schema.jsonnet

    This resulst ins the "subschema" attribute of the "myschema" attribute of the top level object from "my-schema.jsonnet" to be used as the "context" schema.

    A "target" schema is what is used to validate a model and may be specified in a variety of "target forms" with the -t/--target option.  The supported target forms are:

    - an integer indicating an index into the full "context" schema is alloweed when the context is of a sequence form.

    - a simple string indicating either a key of the full "context" schema, allowed only if the context is an object, or indicating the "name" attribute of an moo oschema object held in the context (be it of sequence or object form).

    - a filename with optional "datapath:" prefix.

    When this last form is used the resulting data structure may be any target form listed above or may directly be an moo oschema object or a JSON Schema object.

    By default, this command operates in "scalar mode" meaning a single model and single target schema are processed.  It may instead operate in "sequence mode" which expects a matching sequence of models and target schema.

    Sequence mode is entered when any of the following are true:

    - the --sequence option is given indicating array of models is given

    - more than one -t/--target is given

    - a -t/--target value is a comma-separated list of target forms

    - a -t/--target is a filename with optional "datapath:" prefix and the loaded data produces a list or tuple form.

    The multiple targets are concantenated and the resulting sequence must match the supplied sequence of models.

    In the special cases that all target schema are either in JSON Schema form or are in moo oschema form but lack any type dependency, a context schema is not required.


    '''

    context = None if schema is None else ctx.obj.just_load(schema)
    # always returns list even if target is scalar
    targets = moo.util.resolve_schema(target, context, ctx.obj.just_load)
    if len(targets) > 1:
        sequence = True
    # reflects user data
    models = ctx.obj.load(model)
    if not sequence:
        models = [models]

    if len(targets) != len(models):
        raise ValueError(f'sequence size mismatch: #models:{len(models)}, #targets:{len(targets)}\nDid you forget --sequence?')

    res = moo.ovalid.validate(models, targets, context, not passfail, validator)
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
    Validate a string against a regex.

    Examples

        $ moo regex '^[a-z]$' a

        OKAY: ...
    
        $ moo regex '^[a-z]$' aa

        <statck trace and error>
    
        $ moo regex -R zmq.tcp.uri schema/re.jsonnet 'tcp://127.0.0.1:1234'

        OKAY: ...

    '''
    if rpath:
        regex = ctx.obj.just_load(regex, rpath)

    if only:
        if regex[0] != '^':
            regex = '^' + regex
        if regex[-1] != '$':
            regex = regex + '$'

    valid = dict(type="string", pattern=regex)
    res = moo.oschema.validate(string, valid) # throws
    print(f'OKAY: "{regex}" match gives "{res}"')


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
@click.option('-t', '--target', default=None, multiple=True,
              help="Specify target schema")
@click.argument('oschema')
@click.pass_context
def jsonschema(ctx, output, target, oschema):
    '''
    Convert from moo oschema to JSON Schema
    '''
    from moo.jsonschema import convert

    context = ctx.obj.just_load(oschema)
    if target is None:
        targets = [context]
    else:
        targets = moo.util.resolve_schema(target, context, ctx.obj.just_load)

    jtext = [json.dumps( convert(target, context), indent=4 ) for target in targets]
    ctx.obj.save(output, '\n'.join(jtext))
    

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
    # fixme: this code should move into a module method

    model_deps = ctx.obj.imports(model)
    templ_deps = ctx.obj.imports(templ)

    deps = [os.path.realpath(ctx.obj.resolve(model)), 
            os.path.realpath(ctx.obj.resolve(templ))]
    deps += templ_deps + model_deps
    deps_string = ' '.join(deps)
    result = f'{target}: {deps_string}\n'
    ctx.obj.save(output, result)


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
        # print(f"generating {output}:")
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

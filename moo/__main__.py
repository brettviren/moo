#!/usr/bin/env python3
'''
Main CLI to moo
'''
import os
import json
import click
import moo
from pprint import pprint


class Context:
    '''
    Application context collects parameters and methods common to commands.
    '''
    def __init__(self, dpath="", mpath=(), tpath=(),
                 tla=(), transform=(), graft=()):

        self.dpath = dpath
        self.mpath = mpath
        self.tpath = tpath
        self.tlas = dict()
        if tla:
            self.tlas = moo.util.tla_pack(tla, mpath)
        self.transforms = transform
        self.grafts = graft

    def just_load(self, filename, mpath=None, dpath=None):
        return moo.io.load(self.resolve(filename),
                           mpath or self.mpath,
                           dpath or self.dpath, **self.tlas)

    def load(self, filename, mpath=None, dpath=None):
        '''
        Load a data structure from a file.

        Search mpath for file and return substructure at dpath.
        '''
        model = self.just_load(filename, mpath, dpath)
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

    def transform(self, model):
        'Transform a model'
        if self.transforms:
            model = moo.util.transform(model, self.transforms)
        return model

    def resolve(self, filename, fpath=None):
        '''
        Resolve a filename to absolute path searching fpath.
        '''
        ret = None

        if filename.endswith('.jsonnet'):
            ret = moo.util.resolve(filename, fpath or self.mpath)
        elif filename.endswith('.j2'):
            ret = moo.util.resolve(filename, fpath or self.tpath)
        else:
            ret = moo.util.resolve(filename, fpath or self.mpath)
        if ret is None:
            raise RuntimeError(f'can not resolve {filename}')
        return ret

    def render(self, templ_file, model):
        '''
        Render model against template in templ_file.
        '''
        templ = self.resolve(templ_file, self.tpath)
        helper = self.just_load("moo.jsonnet", dpath="templ")
        return moo.template.render(templ, dict(model=model, moo=helper))

    def imports(self, filename):
        '''
        Return list of files the given file imports
        '''
        filename = self.resolve(filename)
        return moo.imports(filename, self.mpath+self.tpath)

@click.group()
@click.option('-D', '--dpath', default="",
              help="Specify a selection path into the model data structure")
@click.option('-M', '--mpath', envvar='MOO_MODEL_PATH', multiple=True,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="Add directory to model file search paths")
@click.option('-T', '--tpath', envvar='MOO_TEMPLATE_PATH', multiple=True,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="Add directory to template file search paths")
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


@cli.command("validate")
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.option('-S', '--spath', default="",
              help="Specify a search path to find validation schema")
@click.option('-s', '--schema', required=True,
              type=click.Path(exists=True, dir_okay=False, file_okay=True),
              help="JSON Schema to validate against.")
@click.option("--sequence", default=False, is_flag=True,
              help="Assume a sequence of schema and models")
@click.option('-V', '--validator', default="jsonschema",
              type=click.Choice(["jsonschema","fastjsonschema"]),
              help="Specify which validator")
@click.argument('model')
@click.pass_context
def cmd_validate(ctx, output, spath, schema, sequence, validator, model):
    '''
    Validate a model against a schema
    '''
    data = ctx.obj.load(model, ctx.obj.dpath)
    sche = moo.io.load_schema(ctx.obj.resolve(schema), spath)

    if not sequence:
        data = [data]
        sche = [sche]
    else:
        assert(len(data) == len(sche))
    res = list()
    for m, s in zip(data, sche):
        one = moo.util.validate(m, s, validator)
        res.append(one)
    if not sequence:
        res = res[0]
    text = json.dumps(res, indent=4)
    with open(output, 'wb') as fp:
        fp.write(text.encode())


def write(data, output, need_dump=True):
    if need_dump:
        data = json.dumps(data, indent=4)
    with open(output, 'wb') as fp:
        fp.write(data.encode())


@cli.command()
@click.option('-m', '--multi', default="",
              help="Write multiple output files")
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.option('--string/--no-string', '-S/ ', default=False,
              help="Treat output as string not JSON")
@click.argument('model')
@click.pass_context
def compile(ctx, multi, output, string, model):
    '''
    Compile a model to JSON
    '''
    data = ctx.obj.load(model)
    if multi:
        os.makedirs(multi, exist_ok=True)
        for one, dat in data.items():
            one = os.path.join(multi, one)
            write(dat, one, not string)
    else:
        write(data, output, not string)


@cli.command()
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.option('-f', '--format', default='repr',
              type=click.Choice(['repr', 'pretty', 'plain', 'types']),
              help="Output format")
@click.argument('model')
@click.pass_context
def dump(ctx, output, format, model):
    '''
    Like render but print model that would be sent to the template
    '''
    data = ctx.obj.load(model)
    if format == 'repr':
        print(repr(data))
    elif format == 'pretty':
        pprint(data)
    elif format == 'types':
        if isinstance(data, list):
            for one in data:
                print(type(one))
        elif isinstance(data, dict):
            for k, v in data.items():
                print(k, type(v))
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
    '''
    data = ctx.obj.load(model)
    text = ctx.obj.render(templ, data)
    with open(output, 'wb') as fp:
        fp.write(text.encode())
    pass


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
        data = ctx.obj.transform(one["model"], one.get("transform", None))
        text = ctx.obj.render(one["template"], data)
        output = os.path.join(outdir, one["filename"])
        print(f"generating {output}:")
        with open(output, 'wb') as fp:
            fp.write(text.encode())



# @cli.command()
# @click.option('-C', '--outdir', default=".",
#               type=click.Path(exists=False, dir_okay=True, file_okay=False),
#               help="Output directory")
# @click.argument('model')
# @click.pass_context
# def many(ctx, outdir, model):
#     '''
#     Render many files
#     '''
#     # fixme: break out much of this into the modules
#     data = ctx.obj.load(model)
#     models = data.get("models",{})
#     schemas = data.get("schema",{})
#     targets = data.get("targets",[])
#     templates = data.get("templates",{})
#     for target in targets:
#         templname = target["template"]
#         path = target["path"]
#         # fixme: if schema given check model.dpath against it
#         schema = target["schema"]
#         print (f'generating file "{path}" with template "{templname}" using model of type "{schema}"')
#         reldir=os.path.dirname(path)
#         fname = os.path.basename(path)
#         fulldir=os.path.join(outdir,reldir)
#         model = models[target["model"]]
#         dpath = target.get("dpath","")
#         templ = ctx.obj.resolve(templates[templname])
#         output = os.path.join(fulldir, fname)
#         os.makedirs(fulldir, exist_ok=True)
#         text = ctx.obj.render(templ, model)
#         with open(output, 'wb') as fp:
#             fp.write(text.encode())
        


@cli.command()
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.argument('filename')
@click.pass_context
def imports(ctx, output, filename):
    '''
    Emit a list of imports required by the model
    '''
    deps = ctx.obj.imports(filename)
    text = '\n'.join(deps)
    with open(output, 'wb') as fp:
        fp.write(text.encode())

    

def main():
    cli(obj=None)

if '__main__' == __name__:
    main()
    



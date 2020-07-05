#!/usr/bin/env python3
'''
Main CLI to moo
'''
import os
import sys
import json
import click

import jsonschema
#from moo import jsonnet, template, io
# from moo.util import validate, resolve, deref as dereference, tla_pack
import moo

class Context:
    '''
    Application context collects parameters and methods common to commands.
    '''
    def __init__(self, spath="", dpath="", jpath=(), tpath=(), tla=()):
        self.spath = spath
        self.dpath = dpath
        self.jpath = jpath
        self.tpath = tpath
        self.tlas = dict()
        if tla:
            print(tla)
            self.tlas = moo.util.tla_pack(tla, jpath)

    def load(self, filename, jpath=None, dpath=None):
        '''
        Load a data structure from a file.

        Search jpath for file and return substructure at dpath.
        '''
        return moo.io.load(self.resolve(filename),
                           jpath or self.jpath,
                           dpath or self.dpath, **self.tlas)

    def load_schema(self, schema, jpath=None, spath=None):
        '''
        Load a schema structure from a file or URL.  

        Search jpath for file and return substructure at spath.
        '''
        return moo.io.load_schema(self.resolve(schema),
                                  jpath or self.jpath,
                                  spath or self.spath)

    def resolve(self, filename, fpath=None):
        '''
        Resolve a filename to absolute path searching fpath.
        '''
        ret = None

        if filename.endswith('.jsonnet'):
            ret = moo.util.resolve(filename, fpath or self.jpath)
        elif filename.endswith('.j2'):
            ret =  moo.util.resolve(filename, fpath or self.tpath)
        else:
            ret = moo.util.resolve(filename, fpath or self.jpath)
        if ret is None:
            raise RuntimeError(f'can not resolve {filename}')
        return ret

    def render(self, templ_file, model):
        '''
        Render model against template in templ_file.
        '''
        templ = self.resolve(templ_file, self.tpath)
        
        helper = self.load(self.resolve("moo.jsonnet"), dpath = "templ")
        return moo.template.render(templ, dict(model=model, moo=helper))

    def imports(self, filename):
        '''
        Return list of files the given file imports
        '''
        filename = self.resolve(filename)
        if filename.endswith('.jsonnet'):
            return moo.jsonnet.imports(filename, self.jpath)
        if filename.endswith('.j2'):
            return moo.template.imports(filename, self.tpath)
        raise ValueError(f'unknown file type: {filename}')

@click.group()
@click.option('-S', '--spath', default="",
              help="Specify a selection path into the schema data structure")
@click.option('-D', '--dpath', default="",
              help="Specify a selection path into the model data structure")
@click.option('-J', '--jpath', envvar='JSONNET_PATH', multiple=True,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="Extra directory to find Jsonnet files")
@click.option('-T', '--tpath', envvar='JINJA2_PATH', multiple=True,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="Extra directory to find Jinja2 files")
@click.option('-A', '--tla', multiple=True,
              help="Specify a 'top-level argument' as a var=string or var=file.jsonnet")
@click.pass_context
def cli(ctx, spath, dpath, jpath, tpath, tla):
    '''
    moo command line interface
    '''
    ctx.obj = Context(spath, dpath, jpath, tpath, tla)


@cli.command("resolve")
@click.argument('filename')
@click.pass_context
def resolve(ctx, filename):
    '''
    Resolve a filename.
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
def cmd_validate(ctx, output, schema, sequence, validator, model):
    '''
    Validate a model against a schema
    '''
    data = ctx.obj.load(model)
    sche = ctx.obj.load_schema(schema)
    if not sequence:
        data = [data]
        sche = [sche]
    else: assert(len(data) == len(sche))
    res=list()
    for m,s in zip(data,sche):
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
@click.option('--deref', default=None,
              help="Dereference JSON Schema $ref (yes/true or select path)")
@click.argument('model')
@click.pass_context
def compile(ctx, multi, output, string, deref, model):
    '''
    Compile a model to JSON
    '''
    data = ctx.obj.load(model)
    if deref:
        data = dereference(data, deref)
    if multi:
        os.makedirs(multi, exist_ok=True)
        for output, dat in data.items():
            output = os.path.join(multi, output)
            write(dat, output, not string)
    else:
        write(data, output, not string)

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
    moo = ctx.obj.load("moo.jsonnet", dpath = "templ")
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
        text = ctx.obj.render(one["template"], one["model"])
        output = os.path.join(outdir, one["filename"])
        print(f"generating {output}:")
        with open(output, 'wb') as fp:
            fp.write(text.encode())
        


@cli.command()
@click.option('-C', '--outdir', default=".",
              type=click.Path(exists=False, dir_okay=True, file_okay=False),
              help="Output directory")
@click.argument('model')
@click.pass_context
def many(ctx, outdir, model):
    '''
    Render many files
    '''
    # fixme: break out much of this into the modules
    data = ctx.obj.load(model)
    models = data.get("models",{})
    schemas = data.get("schema",{})
    targets = data.get("targets",[])
    templates = data.get("templates",{})
    for target in targets:
        templname = target["template"]
        path = target["path"]
        # fixme: if schema given check model.dpath against it
        schema = target["schema"]
        print (f'generating file "{path}" with template "{templname}" using model of type "{schema}"')
        reldir=os.path.dirname(path)
        fname = os.path.basename(path)
        fulldir=os.path.join(outdir,reldir)
        model = models[target["model"]]
        dpath = target.get("dpath","")
        templ = ctx.obj.resolve(templates[templname])
        output = os.path.join(fulldir, fname)
        os.makedirs(fulldir, exist_ok=True)
        text = ctx.obj.render(templ, model)
        with open(output, 'wb') as fp:
            fp.write(text.encode())
        


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
    



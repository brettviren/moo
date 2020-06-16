#!/usr/bin/env python3
'''
Main CLI to moo
'''
import os
import sys
import json
import click

import jsonschema
from moo import jsonnet, template, io
from moo.util import validate, resolve, deref as dereference


@click.group()
@click.pass_context
def cli(ctx):
    '''
    moo command line interface
    '''
    ctx.ensure_object(dict)

@cli.command("validate")
@click.option('-S', '--spath', default="",
              help="Specify a selection path into the schema data structure")
@click.option('-D', '--dpath', default="",
              help="Specify a selection path into the model data structure")
@click.option('-J', '--jpath', envvar='JSONNET_PATH', multiple=True,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="Extra directory to find Jsonnet files")
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.option('-s', '--schema', type=str,
              help="JSON Schema (a file of JSON schema or a JSON Schema version)")
@click.option('-V', '--validator', default="jsonschema",
              type=click.Choice(["jsonschema","fastjsonschema"]),
              help="Specify which validator")

@click.argument('model')
@click.pass_context
def cmd_validate(ctx, spath, dpath, jpath, output, schema, validator, model):
    '''
    Validate a model against a schema
    '''
    data = io.load(model, jpath, dpath)
    sche = io.load_schema(schema, jpath, spath)
    res = validate(data, sche, validator)
    text = json.dumps(res, indent=4)
    with open(output, 'wb') as fp:
        fp.write(text.encode())



@cli.command()
@click.option('-P', '--path', default="",
              help="Specify a selection path into the model data structure")
@click.option('-J', '--jpath', envvar='JSONNET_PATH', multiple=True,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="Extra directory to find Jsonnet files")
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.option('--string/--no-string', '-S/ ', default=False,
              help="Treat output as string not JSON")
@click.option('--deref', default=None,
              help="Dereference JSON Schema $ref (yes/true or select path)")
@click.argument('model')
@click.pass_context
def compile(ctx, path, jpath, output, string, deref, model):
    '''
    Compile a model to JSON
    '''
    data = io.load(model, jpath, path)
    if deref:
        data = dereference(data, deref)
    if string:
        text = data
    else:
        text = json.dumps(data, indent=4)
    with open(output, 'wb') as fp:
        fp.write(text.encode())

@cli.command()
@click.option('-P', '--path', default="",
              help="Specify a selection path into the model data structure")
@click.option('-J', '--jpath', envvar='JSONNET_PATH', multiple=True,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="Extra directory to find Jsonnet files")
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.argument('model')
@click.argument('templ')
@click.pass_context
def render(ctx, path, jpath, output, model, templ):
    '''
    Render a template against a model.
    '''
    moo = io.load("moo.jsonnet", jpath, "templ")
    data = io.load(model, jpath, path)
    text = template.render(templ, dict(model=data, moo=moo))
    with open(output, 'wb') as fp:
        fp.write(text.encode())

    pass

@cli.command()
@click.option('-T', '--tpath', default="",
              help="Specify directory path to locate templates")
@click.option('-M', '--mpath', default="",
              help="Specify a selection path into the model data structure")
@click.option('-J', '--jpath', envvar='JSONNET_PATH', multiple=True,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="Extra directory to find Jsonnet files")
@click.option('-C', '--outdir', default=".",
              type=click.Path(exists=False, dir_okay=True, file_okay=False),
              help="Output directory")
@click.argument('model')
@click.pass_context
def many(ctx, tpath, mpath, jpath, outdir, model):
    '''
    Render many files
    '''
    # fixme: break out much of this into the modules
    moo = io.load("moo.jsonnet", jpath, "templ")
    data = io.load(model, jpath, mpath)
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
        templ = resolve(templates[templname], tpath)
        output = os.path.join(fulldir, fname)
        os.makedirs(fulldir, exist_ok=True)

        text = template.render(templ, dict(model=model, moo=moo))
        with open(output, 'wb') as fp:
            fp.write(text.encode())
        


@cli.command()
@click.option('-J', '--jpath', envvar='JSONNET_PATH', multiple=True,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="Extra directory to find Jsonnet files")
@click.option('-T', '--tpath', envvar='JINJA2_PATH', multiple=True,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="Extra directory to find Jinja2 files")
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.argument('filename')
@click.pass_context
def imports(ctx, jpath, tpath, output, filename):
    '''
    Emit a list of imports required by the model
    '''
    deps=list()
    if filename.endswith('.jsonnet'):
        deps = jsonnet.imports(filename, jpath)
    if filename.endswith('.j2'):
        deps = template.imports(filename, tpath)
    text = '\n'.join(deps)
    with open(output, 'wb') as fp:
        fp.write(text.encode())


def main():
    cli(obj=dict())

if '__main__' == __name__:
    main()
    



#!/usr/bin/env python3
'''
Main CLI to moo
'''
import os
import sys
import json
import click
from moo import jsonnet, template
from moo.util import select_path


@click.group()
@click.pass_context
def cli(ctx):
    '''
    moo command line interface
    '''
    ctx.ensure_object(dict)

@cli.command()
@click.option('-p', '--path', default="",
              help="Specify a selection path into the model data structure")
@click.option('-J', '--jpath', envvar='JSONNET_PATH', multiple=True,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="Extra directory to find Jsonnet files")
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.argument('model')
@click.pass_context
def compile(ctx, path, jpath, output, model):
    '''
    Compile a model to JSON
    '''
    data = jsonnet.load(model, jpath)
    if path:
        data = select_path(data, path)
    with open(output, 'wb') as fp:
        fp.write(json.dumps(data, indent=4).encode())

@cli.command()
@click.option('-J', '--jpath', envvar='JSONNET_PATH', multiple=True,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="Extra directory to find Jsonnet files")
@click.option('-o', '--output', default="/dev/stdout",
              type=click.Path(exists=False, dir_okay=False, file_okay=True),
              help="Output file, default is stdout")
@click.argument('model')
@click.argument('templ')
@click.pass_context
def generate(ctx, jpath, output, model, templ):
    data = jsonnet.load(model, jpath)
    text = template.render(templ, data)
    with open(output, 'wb') as fp:
        fp.write(text.encode())

    pass

def main():
    cli(obj=dict())

if '__main__' == __name__:
    main()
    



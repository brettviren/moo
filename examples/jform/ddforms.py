#!/usr/bin/env python
'''
This script generates input to the CCM configuration web UI.
'''
import json
import click

from moo.oschema import typeref, fqnhier
from moo.jform import convert as jfschema

def flatten(monolith):
    '''
    Return flat array of all the schema and just the schema.

    Preservers order of monolith.

    If duplicates exist, first time seen sets order.
    '''
    lofs = list()
    have = set()
    for group in monolith:
        for one in group['schema']:
            path = typeref(one)
            if path in have:
                continue
            have.add(path)
            lofs.append(one)
    return lofs

def pathtree(monolith):
    '''
    Return a tree of schema types keyed by dot-path names
    '''
    return fqnhier(flatten(monolith))

def endtype(monolith):
    '''
    Return reference to the last type in each plugin's schema array
    '''
    lasts = list()
    for one in monolith:
        end = one['schema'][-1]
        tr = typeref(end)
        lasts.append(tr)
    return lasts

def modconfrefs(monolith):
    '''
    Return list of typerefs for module-level conf sub-object schema 
    '''
    # note: in practice this will likely grow a lot of hair
    ret = list()
    for group in monolith:
        end = group['schema'][-1]
        path = end['path']
        if path[1] in ("cmdlib", "appfwk", "toy"):
            continue
        name = end['name']
        if not name.startswith("Conf"):
            continue
        ret.append(typeref(end))
    return ret

def modconfs(monolith):
    '''
    Return the modconfs object for list of FQN type refs in hier
    '''
    lofs = flatten(monolith)
    modrefs = modconfrefs(monolith)

    # array of jsonform objects.
    # fixme: we will need to provide "form" when we support anyOf.
    # for now we leave it blank.
    jforms = [dict(schema=jfschema(lofs, typeref))
              for typeref in modrefs]

    ret = dict(name="modconf",
               title="Module-level configuration",
               description="A portion of one 'conf' command object providing one modules configuration",
               forms=jforms)
    return ret

def ddforms(monolith):
    '''
    Convert monolith object to ddforms object
    '''
    cats = [
        modconfs(monolith),
        # confcmds
        # initcmfs
        # bootcmds
    ]
    ret = dict(title="DUNE DAQ Configuration Editor",
               description="Browse, create and modify DUNE DAQ configuration",
               categories = cats)

    return ret

def write_json(data, fname="/dev/stdout"):
    with open(fname, "w") as fp:
        json.dump(data, fp, indent=4)
    

@click.group()
@click.pass_context
def cli(ctx):
    ctx.obj = dict()

@cli.command("jschema")
@click.option("-o", "--output", type=str, default="/dev/stdout",
              help="Give output file or use stdout")
@click.option("-t", "--typeref", type=str,
              help="Give FQN type reference in monolith")
@click.argument("monolith")
def cmd_jschema(output, typeref, monolith):
    '''
    Produce jsonform JSON Schema for one type
    '''
    ml = json.load(open(monolith))
    lofs = flatten(ml)
    dat = jfschema(lofs, typeref)
    write_json(dat, output)


@cli.command("monolith")
@click.option("-o", "--output", type=str, default="/dev/stdout",
              help="Give output file or use stdout")
@click.option("-c", "--command", default="endtype",
              type=click.Choice(["pathtree", "endtype",
                                 "modconfrefs", "ddforms"]),
              help="Set command")
@click.argument("mlfile")
def cmd_monolith(output, command, mlfile):
    '''
    Run command on a monolith file
    '''
    meth = eval(command)
    dat = meth(json.load(open(mlfile)))
    write_json(dat, output)

    
def main():
    cli(obj=None)
if '__main__' == __name__:

    main()

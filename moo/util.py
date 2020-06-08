#!/usr/bin/env python3

import os

def select_path(obj, path, delim='.'):
    '''Select out a part of obj structure based on a path.

    The path is a list or a delim-separated string.

    Any element of the path that looks like an integer will be cast to
    one assuming it indexes an array.

    '''
    if isinstance(path, str):
        path = path.split(delim)
    for one in path:
        if not one:
            break
        try:
            one = int(one)
        except ValueError:
            pass
        obj = obj[one]

    return obj

def validate(model, schema, validator):
    if validator == "jsonschema":
        from jsonschema import validate
        return validate(instance=model, schema=schema)
    if validator == "fastjsonschema":
        from fastjsonschema import validate
        return validate(schema, model)
    raise ValueError(f"unknown validator: {validator}")

def clean_paths(paths):
    if isinstance(paths, str):
        paths = paths.split(":")
    paths = [os.path.realpath(p) for p in paths]
    cwd = os.path.realpath(os.path.curdir)
    if cwd not in paths:
        paths.insert(0, cwd)

    # fixme: moo.jsonnet library probably doesn't belong in the
    # python source directory.
    paths.append(os.path.join(os.path.dirname(__file__)))
    return paths

def resolve(filename, paths=()):
    '''
    Resolve filename against paths.

    Return None if fail to locate file.
    '''
    if not filename:
        raise ValueError("no file name provided")
    if filename.startswith('/'):
        return filename
    for maybe in clean_paths(paths):
        fp = os.path.join(maybe, filename)
        if os.path.exists(fp):
            return fp
    raise ValueError(f"file not found: {filename}")

def deref(data, path=None):
    defs = data.pop("definitions")
    data = deref_defs(data, defs)
    if path in ("yes", "true"):
        return data
    return select_path(data, path)
    

def deref_defs(ctx, defs):
    '''
    Convert special form substructure:

    {"$ref":"#/definitions/<def>"}

    To the value of attribute <def> of defs.
    '''
    if type(ctx) in [int, float, str, bool]:
        return ctx
    if isinstance(ctx, list):
        return [deref_defs(ele, defs) for ele in ctx]
    ret = dict()
    for key, val in ctx.items():
        if isinstance(val, dict) and "$ref" in val:
            ref = val["$ref"]
            ref = ref[len("#/definitions/"):]
            val = select_path(defs, ref, "/")
        ret[key] = deref_defs(val, defs)
    return ret

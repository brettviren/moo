#!/usr/bin/env python3

import os

def select_path(obj, path):
    '''Select out a part of obj structure based on a path.

    The path is a list or a "."-separated string.

    Any element of the path that looks like an integer will be cast to
    one assuming it indexes an array.

    '''
    if isinstance(path, str):
        path = path.split('.')
    for one in path:
        if not one:
            break
        try:
            one = int(one)
        except ValueError:
            pass
        obj = obj[one]

    return obj

def validate(model, schema):
    import jsonschema
    return jsonschema.validate(instance=model, schema=schema)


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


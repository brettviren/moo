#!/usr/bin/env python3

import os
import json
from _jsonnet import *


def try_path(path, rel):
    '''
    Try to open a path
    '''
    if not rel:
        raise RuntimeError('Got invalid filename (empty string).')
    if rel[0] == '/':
        full_path = rel
    else:
        full_path = os.path.join(path, rel)
    if full_path[-1] == '/':
        raise RuntimeError('Attempted to import a directory')

    if not os.path.isfile(full_path):
        return full_path, None
    with open(full_path) as f:
        return full_path, f.read()

def resolve(filename, paths=()):
    '''
    Resolve filename against paths.

    Return None if fail to locate file.
    '''
    if not filename:
        raise ValueError("no file name provided")
    if filename.startswith('/'):
        return filename
    if os.path.exists(filename):
        return os.path.realpath(filename)
    for maybe in paths:
        fp = os.path.join(maybe, filename)
        if os.path.exists(fp):
            return fp
    raise ValueError(f"file not found: {filename}")

def make_import_callback(paths):

    def import_callback(path, rel):
        '''
        Help jsonnet find imports
        '''
        nonlocal paths
        paths = [path] + list(paths)
        for maybe in paths:
            try:
                full_path, content = try_path(maybe, rel)
            except RuntimeError:
                continue
            if content:
                return full_path, content
        raise RuntimeError('File not found')
    return import_callback

def load(fname, paths=(), **kwds):
    '''
    Load a JSON or Jsonnet file.

    For Jsonnet some useful kwds are:
    ext_vars - dictionary of variables, to get via std.extVar()
    ext_codes - dictionary of code, to get via std.extVar()
    native_callbacks - call python from Jsonnet
    import_callbacks - help find imports

    No kwds for JSON, go fish.
    '''
    paths = [os.path.realpath(p) for p in paths]
    # fixme: moo.jsonnet library probably doesn't belong in the
    # python source directory.
    paths.append(os.path.join(os.path.dirname(__file__), 'jsonnet'))
    fname = resolve(fname, paths)

    if fname.endswith(".jsonnet"):
        text = evaluate_file(fname, 
                             import_callback = make_import_callback(paths),
                             **kwds)
    elif fname.endswith(".json"):
        text = open(fname).read()
    else:
        return
    return json.loads(text)


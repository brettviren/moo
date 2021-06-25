#!/usr/bin/env python3
'''
File and other I/O
'''
import os
from moo.util import clean_paths, resolve, select_path
import moo.jsonnet
import anyconfig

# Application may set this.  It is a fallback which will be consulted
# if a file to be loaded is not otherwise located.  See load().
default_load_path = []

def load(filename, fpath=(), dpath = None, **kwds):
    '''Load a file and return its data structure.

    If dpath given, return substructure at that "path" in the
    resulting data structure.

    If filename is not absolute, it will be searched for first in the
    current working directory, then moo's built-in directory, then in
    any user-provided paths in "fpath" and finally in directories
    provided by moo.io.default_load_path.  The application is free to
    provide this fallback.  When moo is used from its CLI the
    MOO_LOAD_PATH environment variable is consulted.

    '''
    fmt = os.path.splitext(filename)[-1]

    paths = clean_paths(fpath) + list(default_load_path)
    filename = resolve(filename, paths)
    
    if fmt in (".jsonnet",".schema"):
        data = moo.jsonnet.load(filename, paths, **kwds)
    elif fmt in (".csv",):
        data = moo.csvio.load(filename, paths, **kwds)
    elif fmt in (".xls", ".xlsx"):
        data = moo.xls.load(filename, paths, **kwds)
    else:
        data = anyconfig.load(filename)
    if data is None:
        raise ValueError(f'no data from {filename}')
    if dpath:
        return select_path(data, dpath)
    return data

def load_schema(uri, fpath, dpath=None):
    '''Return a schema data structure.

    If uri can be located as a file in fpath, load it and apply dpath
    reduction.  O.w. test it as being a specifier of a JSON Schema.

    '''
    if not uri:
        return {"$ref": "https://json-schema.org/draft-07/schema"}
    try:
        fname = resolve(uri, fpath)
        print(f'load_schema from {fname}')
        return load(uri, fname, dpath)
    except ValueError:
        pass
    if uri.startswith("http"):  # any URL
        return {"$ref": uri}
    if uri.startswith('draft-0'):  # numbered releases
        return {"$ref": f'https://json-schema.org/{uri}/schema'}
    if uri.startswith('20'):    # date based releases
        return {"$ref": f'https://json-schema.org/draft/{uri}/schema'}
    raise ValueError(f'can not load schema "{uri}"')


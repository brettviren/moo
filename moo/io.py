#!/usr/bin/env python3
'''
File and other I/O
'''

from moo.util import clean_paths, resolve, select_path
import moo.jsonnet
import anyconfig

def load(filename, fpath=(), dpath = None, **kwds):
    '''Load a file and return its data structure.  

    If dpath given, return substructure at that path.

    If fpath is given, it is used as a file search path.
    '''
    paths = clean_paths(fpath)
    filename = resolve(filename, paths)
    
    if filename.endswith(".jsonnet"):
        data = moo.jsonnet.load(filename, paths, **kwds)
    elif filename.endswith(".csv"):
        data = moo.csv.load(filename, paths, **kwds)
    else:
        data = anyconfig.load(filename)
    if data is None:
        raise ValueError(f'no data from {filename}')
    if dpath:
        return select_path(data, dpath)
    return data

def load_schema(uri, fpath, spath):
    '''Return a schema data structure.

    If uri can be loacated as a file in fpath, load it and apply spath reduction.
    O.w. test it as being a specifier of a JSON Schema.
    '''
    if not uri:
        return {"$ref":"https://json-schema.org/draft-07/schema"}
    try:
        fname = resolve(uri, fpath)
        return load(uri, fpath, spath)
    except ValueError:
        pass
    if uri.startswith("http"):  # any URL
        return {"$ref": uri}
    if uri.startswith('draft-0'): # numbered releases
        return {"$ref": f'https://json-schema.org/{uri}/schema'}
    if uri.startswith('20'):    # date based releases
        return {"$ref": f'https://json-schema.org/draft/{uri}/schema'}
    raise ValueError(f'can not load schema "{uri}"')




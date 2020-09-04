#!/usr/bin/env python3
'''
Convert Avro schema into Python objects in a statically typed manner as possible.
'''

import dataclasses
from typing import List
from enum import Enum

def get_type(typename, types):
    if isinstance(typename, list): # fixme: list ending in null means optional field
        return get_type(typename[0], types)

    if isinstance(typename, dict):
        tname = typename['type']
        if tname == "array":
            tname = typename['items']
            typ = types[tname]
            return List[typ]
        return get_type(tname, types)
    return types[typename]      # fixme: handle more complex types like array

def make_enum(schema, types):
    ename = schema["name"]
    evals = schema["symbols"]
    e =  Enum(ename, evals)
    types[ename] = e
    return types

def make_record(schema, types):
    cname = schema["name"]
    cfields = list()
    for field in schema["fields"]:
        fname = field["name"]
        ftype = get_type(field["type"], types)
        cfields.append((fname, ftype))
    cls = dataclasses.make_dataclass(cname, cfields)
    types[cname] = cls
    return types
    

def dispatch(schema, types):
    if isinstance(schema, list):
        for one in schema:
            types = dispatch(one, types)
        return types
    typ = schema['type']
    meth = eval(f'make_{typ}')
    return meth(schema, types)

def define(schema):
    '''
    Return a module-like object with classes defined from given schema
    '''
    types = dict(string=str, int=int)
    types = dispatch(schema, types)
    return types
    

if __name__ == '__main__':
    import sys
    import json
    schema = json.loads(open(sys.argv[1], 'rb').read().decode())
    types = define(schema)
    CoreSchema = type('CoreSchema', (object,) , types)
    for k,v in types.items():
        assert(hasattr(CoreSchema, k))
    exe = CoreSchema.Executable('myprog')
    osv = CoreSchema.OSVersion.CentOS8
    host = CoreSchema.Host('myhostid', osv)
    ctr = CoreSchema.Controller('myid', exe, host, [])
    print(ctr)

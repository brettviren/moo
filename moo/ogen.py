#!/usr/bin/env python3
'''
Convert moo object schema into Python objects in a statically typed manner as possible.
'''

import sys
from types import ModuleType
from importlib import import_module
import numpy
import dataclasses
# from typing import List
from enum import Enum

def dispatch(schema, types):
    if isinstance(schema, list):
        for one in schema:
            types = dispatch(one, types)
        return types
    typ = schema['type']
    meth = eval(f'make_{typ}')
    return meth(schema, types)


def module_at(path):
    'Return module found by path, attaching/creating module path as needed'
    if isinstance(path, str):
        path = path.split(".")

    loc = []
    mod = None
    last_mod = None
    for p in path:
        loc.append(p)
        dot = '.'.join(loc)
        try:
            mod = import_module(dot)
        except ModuleNotFoundError:
            mod = ModuleType(p)
            sys.modules[dot] = mod
        if last_mod:
            setattr(last_mod, p, mod)
        last_mod = mod
    return mod

def resolve(tref):
    '''Resolve a type from a dot-path type reference.'''
    mpath = tref.split(".");
    tname = mpath.pop()
    m = import_module(".".join(mpath))
    return getattr(m, tname)

def make_boolean(ost):
    return bool

def make_number(ost):
    'Return something that can make a number matching ost'
    dtype = ost["dtype"]
    name = ost["name"]
    def Number(val):
        # fixme: raise if constraints violated.
        return numpy.dtype(val, dtype).item()
    Number.__doc__ = ost.get("doc", f"Make a {name} number of dtype {dtype}")
    Number.__name__ = name
    return Number

def make_string(ost):
    'Return something that can make a string matching ost'
    name = ost["name"]
    def String(val):
        # fixme: check pattern/format
        return str(val)
    String.__doc__ = ost.get("doc", f"Make a {name} string")
    String.__name__ = name
    return String


def make_sequence(ost):
    'Return something that makes a sequence matching ost'
    name = ost["name"]
    items = ost["items"]
    def Sequence(val):
        Item = resolve(items)
        return [Item(i) for i in val]
    Sequence.__doc__ = ost.get("doc", f"Make a {name} sequence of {items}")
    Sequence.__name__ = name
    return Sequence

def make_enum(ost):
    'Return something that makes an enum matching ost'
    ename = ost["name"]
    evals = ost["symbols"]
    return Enum(ename, evals)

def make_record(ost):
    cname = ost["name"]
    cfields = list()
    for field in ost["fields"]:
        fname = field["name"]
        ftype = resolve(field["item"])
        cfields.append((fname, ftype))
    return dataclasses.make_dataclass(cname, cfields)

    

def make_any(ost):
    raise NotImplemented

def make_anyOf(ost):
    raise NotImplemented

def make_allOf(ost):
    raise NotImplemented

def make_oneOf(ost):
    raise NotImplemented


def typify(ost):
    '''Create and return a Python class from given oschema type.'''
    sclass = ost["schema"]
    func = eval(f'make_{sclass}')

    name = ost["name"]
    path = ost["path"]
    if isinstance(path, str):
        path = path.split(".")


    m = module_at(path)
    # if hasattr(m, name):
    #     p = ".".join(path + [name])
    #     raise AttributeError(f"type exists: {p}")
        
    t = func(ost)
    setattr(m, name, t)
    return t;


def test():
    types = [
        dict(path="a.b",name="TF",schema="boolean"),
        dict(path="a.b",name="Bools", schema="sequence", items="a.b.TF"),
        dict(path="a.b",name="Stuff", schema="record", fields=[
            dict(name="tf", item="a.b.TF"),
            dict(name="many", item="a.b.Bools"),
        ])
    ]
    return [typify(t) for t in types]


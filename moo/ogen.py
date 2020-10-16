#!/usr/bin/env python3
'''Convert moo object schema into Python types.

Instances of the types may be aggregated into data structure and that
structure may be translated into POD and eventually into JSON
'''

import re
import sys
from importlib import import_module
from types import ModuleType

from jsonschema import validate as js_validate
from jsonschema import draft7_format_checker
from jsonschema.exceptions import ValidationError


class BaseType:
    pass


def ost_path(ost):
    'Return ost path as list'
    path = ost.get("path", [])
    if isinstance(path, str):
        path = path.split('.')
    return path


def ismatchedtype(val, ost):
    'Return True if val is instance of schema given by ost'
    if not isinstance(val, BaseType):
        return False
    klass = getattr(val, '__class__', None)
    if not klass:
        return False
    val_ost = getattr(klass, '_ost', None)
    if not val_ost:
        return False
    if val_ost["name"] != ost["name"]:
        return False
    if val_ost["schema"] != ost["schema"]:
        return False
    if ost_path(val_ost) != ost_path(ost):
        return False
    if type(val).__qualname__ != ost["name"]:
        return False
    return True


# Washers return pod data appropriate for their schema class.  Either
# args or kwds or both are given and args[0] will NOT be a BaseType.


def wash_boolean(types, ost, *args, **kwds):
    name = ost["name"]
    if not args:
        raise ValueError('illegal boolean setting for {name}')
    val = args[0]
    if isinstance(val, bool):
        return val
    if isinstance(val, str):
        if val.lower() in ("yes", "true", "on"):
            return True
        if val.lower() in ("no", "false", "off"):
            return False
    raise ValueError(f'illegal {name} boolean string value: "{val}"')


def wash_number(types, ost, *args, **kwds):
    name = ost["name"]
    if not args:
        raise ValueError(f'illegal number setting for {name}')
    val = args[0]
    if isinstance(val, str):
        if "." in val:
            return float(val)
        else:
            return int(val)
    if isinstance(val, float) or isinstance(val, int):
        return val
    if isinstance(val, BaseType):
        raise ValueError(f'schema mismatch for number {name}: {val}')

    raise ValueError(f'illegal {name} number: {val}')


def wash_string(types, ost, *args, **kwds):
    name = ost["name"]
    if not args:
        raise ValueError(f'illegal string setting for {name}')
    val = args[0]
    if not isinstance(val, str):
        raise ValueError(f'illegal string {name} value: {val}')

    # let jsonschema do heavy lifting
    schema = dict(type="string")
    if "format" in ost:
        schema["format"] = ost["format"]
    if "pattern" in ost:
        schema["pattern"] = ost["pattern"]
    try:
        js_validate(instance=val, schema=schema,
                    format_checker=draft7_format_checker)
    except ValidationError as verr:
        raise ValueError(f'illegal string format {name} value: {val}') from verr
    return val



def wash_sequence(types, ost, *args, **kwds):
    name = ost["name"]
    if not args:
        raise ValueError(f'illegal sequence setting for {name}')
    seq = args[0]
    items_type = types[ost["items"]]
    return [items_type(one) for one in seq]


def wash_enum(types, ost, *args, **kwds):
    name = ost["name"]
    if not args:
        if "default" in ost:
            return ost["default"]
        raise ValueError(f'illegal enum setting for {name}: (none)')
    val = args[0]
    symbols = ost['symbols']
    if isinstance(val, str) and val in symbols:
        return val
    raise ValueError(f'illegal enum {name} value: "{val}"')


def update_record(have, want):
    return dict(have or dict(), **want)


def wash_record(types, ost, *args, **kwds):
    name = ost["name"]
    if not any([args, kwds]):
        raise ValueError(f'no mapping provided for {name}')
    thing = dict()
    if args:
        thing.update(args[0])
    if kwds:
        thing.update(kwds)
    fields = ost["fields"]
    out = dict()
    for field in fields:
        fname = field['name']
        item_type = types[field['item']]
        try:
            fval = thing[fname]
        except KeyError:
            if "default" in field:
                fval = item_type(field["default"])
            else:
                fval = item_type()

        out[fname] = item_type(fval)
    return out


def pod_record(this):
    out = dict()
    for field in this._ost["fields"]:
        fname = field["name"]
        fitem = this._value[fname]
        out[fname] = fitem.pod()
    return out
        

def wash_any(types, ost, *args, **kwds):
    'Should never be called'
    raise ValueError('illegal any setting for {name}'.format(**ost))


def resolve(tref):
    '''Resolve dot-path type reference to type.'''
    mpath = tref.split(".")
    tname = mpath.pop()
    mod = import_module(".".join(mpath))
    return getattr(mod, tname)


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


def promote(sctype):
    '''
    Promote a schema class type (ie as made by TypeBuilder) to Python
    '''
    mod = module_at(sctype._ost["path"])
    setattr(mod, sctype._ost["name"], sctype)


class TypeBuilder:
    def __init__(self):
        self._types = dict()

    def promote(self, type_name):
        'Promote a type to Python'
        sctype = self._types[type_name]
        promote(sctype)

    def promote_all(self):
        'Promote all types to Python'
        for sctype in self._types.values():
            promote(sctype)

    def make(self, **ost):
        'Make a type described by the moo oschema type structure'
        name = ost["name"]
        scname = ost["schema"]
        washer = globals()[f"wash_{scname}"]
        try:
            updater = globals()[f"update_{scname}"]
        except KeyError:
            updater = lambda me, you: you
        try:
            podder = globals()[f"pod_{scname}"]
        except KeyError:
            podder = lambda me: me._value

        def setter(this, *args, **kwds):
            value = None
            if args and ismatchedtype(args[0], ost):
                args = list(args)
                val = args.pop(0)
                value = val.pod()
            if value is None or any([args, kwds]):
                washed_value = washer(self._types, ost, *args, **kwds)
                value = updater(value, washed_value)
            this._value = value
        setter.__doc__ = f'Set instance of schema class {scname} type {name}'

        typ = type(name, (BaseType,), {
            "__init__": setter, "update": setter, "pod": podder, "_ost": ost})

        path = ost_path(ost)
        doc = ost.get("doc", "")
        dotpath = ".".join(path)
        fullpath = ".".join(list(path)+[name])
        if doc:
            doc = doc.format(dotpath=dotpath, fullpath=fullpath, **ost)
        typ.__doc__ = doc or f'Schema class {scname} type {fullpath}'
        typ.__qualname__ = name
        typ.__module__ = dotpath
        print(f'Register {typ}')
        self._types[fullpath] = typ
        return typ


# fixme: give additional methods to make sequence and records act like
# list and dict.

## todo:
# anyOf
# allOf
# oneOf

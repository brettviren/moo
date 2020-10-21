import sys
from importlib import import_module
from types import ModuleType


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
            mod.__name__ = dot
            sys.modules[dot] = mod
            #print(f'adding module {mod} at {dot}')
        if last_mod:
            setattr(last_mod, p, mod)
        last_mod = mod
    return mod


from moo.oschema import untypify


def find_type(types, fqn):
    'In list of types return one with matching fully qualified name'
    path, name = fqn.rsplit('.', 1)
    for typ in untypify(types):
        if '.'.join(typ['path']) == path and typ['name'] == name:
            return typ
    raise KeyError(f"no oschema type found: {type(fqn)} {fqn}")

def debug(text):
    from rich.pretty import pprint
    pprint(text)
    return ''

def listify(thing, delim="."):
    'Return thing as a list.  If string split on delim'
    if not thing:
        return list()
    if isinstance(thing, str):
        return thing.split(delim)
    return list(thing)


def relpath(longpath, starting):
    'Remove as much of starting from start of longpath as can before diverging'
    longpath = listify(longpath)
    if not starting:
        return longpath
    starting = listify(starting)
    if longpath[0] != starting[0]:
        # err = f'paths do not share common prefix: f{longpath} / f{starting}'
        # raise ValueError(err)
        return longpath
    return relpath(longpath[1:], starting[1:])

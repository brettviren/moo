from moo.oschema import untypify


def find_type(types, fqn):
    'In list of types return one with matching fully qualified name'
    path, name = fqn.rsplit('.', 1)
    for typ in untypify(types):
        if '.'.join(typ['path']) == path and typ['name'] == name:
            return typ
    raise KeyError(f"no oschema type found: {type(fqn)} {fqn}")

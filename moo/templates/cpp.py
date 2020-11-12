'''
This provides support for templates that produce C++ code.

See also ocpp.jsonnet and ocpp.hpp.j2.
'''

from .util import find_type
from moo.oschema import untypify


def literal_value(types, fqn, val):
    '''Convert val of type typ to a C++ literal syntax.'''
    typ = find_type(types, fqn)
    schema = typ['schema']

    if schema == "sequence":
        if val is None:
            return '{}'
        seq = ', '.join([literal_value(types, typ['items'], ele) for ele in val])
        return '{%s}' % seq

    if schema == "number":
        # fixme truncate if int?
        if val is None:
            return "0"
        return f'{val}'

    if schema == "string":
        if val is None:
            return '""'
        return f'"{val}"'

    if schema == "enum":
        if val is None:
            val = typ.get('default', None)
        if val is None:
            val = typ.symbols[0]
        nsp = list(typ['path']) + [typ['name'], val]
        return '::'.join(nsp)

    if schema == "record":
        val = val or dict()
        seq = list()
        for f in typ['fields']:
            fval = val.get(f['name'], f.get('default', None))
            if fval is None:
                break
            cppval = literal_value(types, f['item'], fval)
            seq.append(cppval)
        return '{%s}' % (', '.join(seq))

    if schema == "any":
        return '{}'

    return val                  # go fish


def field_default(types, field):
    'Return a field default as C++ syntax'
    field = untypify(field)
    types = untypify(types)
    return literal_value(types, field['item'], field.get('default', None))


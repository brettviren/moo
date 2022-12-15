'''
This provides support for templates that produce python code.
See also ocpp.jsonnet and ocpp.hpp.j2.
This is added to the environment via the jinjaint module.
'''
import sys
from .util import find_type
from moo.oschema import untypify
import numpy

# fixme: this reproduces some bits that are also in otypes.

def literal_value(types, fqn, val):
    '''Convert val of type typ to a python literal syntax.'''
    typ = find_type(types, fqn)
    schema = typ['schema']

    if schema == "boolean":
        if not val:
            return 'False'
        return 'True'

    if schema == "sequence":
        if val is None:
            return '[]'
        seq = ', '.join([literal_value(types, typ['items'], ele) for ele in val])
        return '[%s]' % seq

    if schema == "number":
        dtype = typ["dtype"]
        dtype = numpy.dtype(dtype)
        val = numpy.array(val or 0, dtype).item() # coerce
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
        nsp = [typ['name'], val]
        return '.'.join(nsp)

    if schema == "record":
        val = val or dict()
        seq = list()
        for f in typ['fields']:
            fval = val.get(f['name'], f.get('default', None))
            if fval is None:
                break
            pyval = f['name']+'='+literal_value(types, f['item'], fval)
            seq.append(pyval)

        record_name = typ["name"]
        record_args = "   "+",\n   ".join(seq)
        s = '%s(\n%s)' % (record_name, record_args)
        return s

    if schema == "any":
        return '{}'

    if schema == "oneOf" :
        return '{}'

    sys.stderr.write(f'moo.templates.py: warning: unsupported default python record field type {schema} for {fqn} using native value')
    return val                  # go fish


def field_default(types, field):
    'Return a field default as python syntax'
    field = untypify(field)
    types = untypify(types)
    return literal_value(types, field['item'], field.get('default', None))

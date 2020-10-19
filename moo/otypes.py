#!/usr/bin/env python
'''Provide Python types corresponding to oschema.

Every type is a class with a constructor that may take an instance of
the same type or type-specific initialization data.  An update()
method is provided of a similar signature.  A pod() returns instance
data in a form sustable for use as schema instance data.

'''

import numpy
from moo.modutil import resolve, module_at

class BaseType:
    pass

class Record(BaseType):
    '''
    The oschema record class in Python
    '''

    _name = None
    _value = dict()
    _fields = ()

    def update(self, *args, **kwds):
        """
        Update this record.
        """
        val = dict()
        if args and args[0] is not None:
            inst = args[0]
            if isinstance(inst, dict):
                val.update(**inst)
            elif self.isme(val):
                val.update(**inst.pod())
            else:
                raise ValueError("illegal instance for record type %s"%self._name)
        val.update(**kwds)
        for f in self._fields:
            fval = val.get(f, None)
            if fval is None:
                continue
            setattr(self, f, fval)  # validates

    def __repr__(self):
        return '<record %s, fields: {%s}>' % (self._name, ','.join(self._fields))

def record_code(**ost):
    'Make a record type'
    ost.setdefault("doc", "")
    fields = ost['fields']
    field_name_list = ','.join(['"{name}"'.format(**f) for f in fields])
    field_args_fwd = ','.join(['{name}={name}'.format(**f) for f in fields])

    klass = '''
class {name}(Record):
    """
    Record type {name} with fields: {field_name_list}

    {doc}
    """
    _fields = ({field_name_list},)
    _name = "{name}"

    def isme(self, val):
        return isinstance(val, {name})
'''.format(field_name_list=field_name_list, **ost)

    field_list = list()
    for field in fields:
        field.setdefault('default')
        one = '{name}:{item} = {default}'.format(**field)
        field_list.append(one)

    init = '''
    def __init__(self, inst=None, {field_list}):
        """
        Create a record type {name}.
        """
        self._value = dict()
        self.update(inst, {field_args_fwd})
'''.format(field_list=','.join(field_list),
           field_args_fwd=field_args_fwd, **ost)

    acc = list()
    for field in fields:
        one = '''
    @property
    def {name}(self):
        return self._value["{name}"]

    @{name}.setter
    def {name}(self, value):
        self._value["{name}"] = {item}(value)
'''.format(**field)
        acc.append(one)
    code = '\n'.join([klass, init] + acc)
    return code


class Sequence(BaseType):
    '''
    The oschema sequence class
    '''
    _value = ()

    def pod(self):
        return [one.pod() for one in self._value]

    def __init__(self, val):
        self.update(val)

def sequence_code(**ost):
    ost.setdefault("doc", "")
    klass = '''
class {name}(Sequence):
    """
    A {name} sequence holding type {items}.
    {doc}
    """

    def __repr__(self):
        return '<sequence {name} %d:[{items}]>'%len(self._value)

    def update(self, val):
        """
        Update a {name} with another {name} or a sequence compatible with {items}
        """
        if isinstance(val, {name}):
            val = [one.pod() for one in val]
        self._value = [{items}(one) for one in val]
'''.format(**ost)
    return klass

class String(BaseType):
    '''
    The oschema string class
    '''
    _name = None
    _value = None

    def __init__(self, val):
        self.update(val)

    def pod(self):
        return self._value

    def __repr__(self):
        if self._value is None:
            return '<string %s: None>'%self._name
        pod = self.pod()
        if len(pod) > 10:
            pod = pod[:10] + "..."
        return '<string %s: %s>' % (self._name, pod)


def string_code(**ost):
    'Make a string type'

    ost.setdefault("pattern", None)
    ost.setdefault("format", None)
    ost.setdefault("doc", "")

    klass = '''
class {name}(String):
    """
    String type {name}.
    - pattern: {pattern}
    - format: {format}
    {doc}
    """

    def update(self, val):
        "Update the string {name}"
        if isinstance(val, {name}):
            self._value = val.pod()
            return
        if not isinstance(val, str):
            raise ValueError('illegal type for string {name}: %s'%(type(val),))
'''
    schema=dict(type="string")
    if ost["pattern"] or ost["format"]:
        if ost["pattern"]:
            schema["pattern"] = ost["pattern"]
        if ost["format"]:
            schema["format"] = ost["format"]
        klass += '''
        from jsonschema import validate as js_validate
        from jsonschema import draft7_format_checker
        from jsonschema.exceptions import ValidationError
        try:
            js_validate(instance=val, schema={jsschema},
                        format_checker=draft7_format_checker)
        except ValidationError as verr:
            raise ValueError(f'illegal format for string {name}') from verr
'''
    klass += '''
        self._value = val
'''
        
    return klass.format(jsschema=schema, **ost)


class Boolean(BaseType):
    '''
    The oschema boolean class
    '''
    _name = None
    _value = None

    def __init__(self, val):
        self.update(val)

    def pod(self):
        if self._value is None:
            raise ValueError("boolean is unset")
        return True if self._value else False

    def __repr__(self):
        if self._value is None:
            return '<boolean %s: None>' % self._name
        return '<boolean %s: %s>' % (self._name, self.pod())


def boolean_code(**ost):
    'Make a boolean'
    ost.setdefault("doc", "")
    klass = '''
class {name}(Boolean):
    """
    A {name} boolean
    {doc}
    """

    _name = "{name}"

    def update(self, val):
        if isinstance(val, {name}):
            self._value = val.pod()
        if isinstance(val, bool):
            self._value = val
            return
        if isinstance(val, int):
            self._value = False if val == 0 else True
            return
        if isinstance(val, str):
            if val.lower() in ("yes", "true", "on"):
                self._value = True
                return
            if val.lower() in ("no", "false", "off"):
                self._value = False
                return
            raise ValueError('illegal {name} boolean string value: %s' % (val,))
        raise ValueError('illegal {name} boolean value: %r' % (val,))
    
'''.format(**ost)
    return klass


class Number(BaseType):
    '''
    The oschema number class
    '''

    _value = None
    _name = None

    def __init__(self, val):
        self.update(val)

    def pod(self):
        return self._value.item()

    def __repr__(self):
        if self._value is None:
            return '<number %s: None>' % self._name
        return '<number %s: %s>' % (self._name, self.pod())


def number_code(**ost):
    'Make a number type'
    klass = '''
class {name}(Number):
    """
    A number type {name}
    """
    _name = "{name}"

    def intern(self, val):
        # fixme: add numeric constraints here
        self._value = numpy.array(val, "{dtype}")

    def update(self, val):
        if type(val) in (int, float, str):
            self.intern(val)
            return
        if isinstance(val, {name}):
            self.intern(val.pod())
            return
        raise ValueError("illegal value for number type {name} (%r): %r"%(self,val))
'''.format(**ost)
    return klass


class Enum(BaseType):
    '''
    The oschema class enum.
    '''

    _value = None

    def __init__(self, val=None):
        self.update(val)

    def pod(self):
        if self._value is None:
            raise ValueError("Enum with no value")
        return self._value


def enum_code(**ost):
    'Make an enum type'
    ost.setdefault("doc","")
    klass = '''
class {name}(Enum):
    """
    Enum type {name} [{symbols}]
    {doc}
    """

    _value = "{default}"
    _symbols = tuple({symbols})

    def __repr__(self):
        if self._value is None:
            return '<enum {name}: None>'
        return "<enum {name}: '%s' of {symbols}>" % (self._value,)

    def update(self, val=None):
        if isinstance(val, {name}):
            self._value = val.pod()
            return
        if val is None:
            self._value = "{default}"
            return
        if isinstance(val, str):
            ind = self._symbols.index(val.lower())
            self._value = self._symbols[ind]
            return
        raise ValueError("unknown value for enum {name}: %r"%(val,))
'''.format(**ost)
    return klass


class Any(BaseType):
    '''
    The oschema class any.
    '''

    _value = None               # holds any BaseType

    def __init__(self, val):
        self.update(val)

    def pod(self):
        if self._value is None:
            raise ValueError("any type is unset")
        return self._value.pod()

def any_code(**ost):
    ost.setdefault("doc","")

    klass = '''
class {name}(Any):
    """
    The any type {name}.  

    Can hold any oschema type except Any types that are not {name}.

    {doc}
    """

    def __repr__(self):
        if self._value is None:
            return '<any {name}: None>'
        return "<any {name}: %s>" % (self._value,)
        

    def update(self, val):
        if isinstance(val, {name}):
            self._value = val._value
            return
        if isinstance(val, Any):
            raise ValueError("cross any updates not allowed")
        if isinstance(val, BaseType):
            self._value = val
            return
        raise ValueError("any type {name} requires oschema type")
'''.format(**ost)
    return klass

def get_deps(deps=None, **ost):
    '''
    Return provided dependencies or calcualte based on schema class.
    '''
    if deps is not None:
        return deps
    schema = ost["schema"]
    deps = set()
    if schema == "record":
        return [f['item'] for f in ost['fields']]
    if schema == "sequence":
        return [ost['items']]
    return []


def deps_code(**ost):
    '''
    Return code to import dependencies.
    '''
    deps = set()
    for dep in get_deps(**ost):
        if "." in dep:
            path, klass = dep.rsplit('.', 1)
            deps.add(f'import {path}')
    deps = list(deps)
    deps.sort()
    return '\n'.join(deps)


def make_type(**ost):
    '''
    Make a Python type from the oschema.
    '''
    code = deps_code(**ost)
    coder = globals()["{schema}_code".format(**ost)]
    code += coder(**ost)
    #print(code)
    exec(code, globals())
    class_name = ost["name"]
    klass = globals()[class_name]
    path = ost.get("path", None)
    if path:
        mod = module_at(path)
        setattr(mod, class_name, klass)
        klass.__module__ = mod.__name__
        #print(path,mod,klass)
    return klass

def test():
    make_type(name="Age", doc="An age in years", schema="number", dtype='i4', path='a.b')
    from a.b import Age
    a42 = Age(42)
    print(Age, a42)
    a43 = Age(a42)

    make_type(name="Person", doc="A record for a person", schema="record", path='a.b',
              fields=[dict(name="age", item="a.b.Age", default=42)])
    from a.b import Person
    print(Person, Person(age=a42))


#!/usr/bin/env python
'''Provide Python types corresponding to oschema.

Every type is a class with a constructor that may take an instance of
the same type or type-specific initialization data.  An update()
method is provided of a similar signature.  A pod() returns instance
data in a form sustable for use as schema instance data.

'''

from abc import ABC, abstractmethod
from moo.modutil import module_at


def fullpath(**kwds):
    path = kwds['path']
    if isinstance(path, str):
        path = path.split('.')
    return '.'.join(path + [kwds['name']])


class BaseType(ABC):
    'Base of all Python oschema types'

    @abstractmethod
    def pod(self):
        'Return value as plain old data'
        pass

    @abstractmethod
    def update(self, val, *args, **kwds):
        'Update self with new value'
        pass


class Record(BaseType):
    '''
    The oschema record class in Python
    '''

    _value = dict()
    _fields = ()

    def pod(self):
        'Return record as a dictionary of POD attributes'
        ret = dict()

        return {k: getattr(self, k) for k in self._fields}


    def __repr__(self):
        return '<record %s, fields: {%s}>' % \
            (self.__class__.__name__, ', '.join(self._fields))


def record_code(**ost):
    'Make a record type'
    ost.setdefault("doc", "")
    ost['fullpathname'] = fullpath(**ost)
    fields = ost['fields']
    ost['field_name_list'] = ', '.join(['"{name}"'.format(**f) for f in fields])
    ost['field_args_fwd'] = ', '.join(['{name}={name}'.format(**f) for f in fields])
    field_arg_list = list()
    for field in fields:
        d = field.get("default", None)
        # if isinstance(d, str):
        #     d = '"%s"' % d
        field['default'] = d
        one = '{name}:{item} = {default}'.format(**field)
        field_arg_list.append(one)
    ost['field_arg_list'] = ', '.join(field_arg_list)


    klass = '''
class {name}(Record):
    """
    Record type {name} with fields: {field_name_list}

    {doc}
    """
    _fields = ({field_name_list},)
    _defaults = {

'''.format(**ost)

    init = '''
    def __init__(self, *args, {field_arg_list}):
        """
        Create a {name} record type
        """
        self._value = dict()
        # first set defaults enced in init kwdargs
        self.update({field_args_fwd})
        if args:
            self.update(*args)
'''.format(**ost)

    update = '''
    def update(self, *args, **kwds):
        """
        Update record {name}.
        """
        val = dict()
        if args:
            inst = args[0]
            if isinstance(inst, dict):
                val.update(**inst)
            elif isinstance(inst, {name}):
                val.update(**inst.pod())
            else:
                raise ValueError("illegal instance for record type {name}")
        val.update(**kwds)
        for fkey in self._fields:
            if fkey in val and val[fkey] is not None:
                setattr(self, fkey, val[fkey])
'''.format(**ost)

    pod = '''
    def pod(self):
        """
        Return plain old data representation of a {name} record
        """
        ret = dict()'''
    for field in fields:
        field.setdefault("default", "None")
        field.setdefault("optional", "False")
        pod += '''
        ret["{name}"] = self._value.get("{name}", {default})
        if ret["{name}"] is None and not {optional}:
            raise ValueError("required field unset: {name}")'''

    acc = list()
    for field in fields:
        one = '''
    @property
    def {name}(self):
        return self._value["{name}"].pod()

    @{name}.setter
    def {name}(self, value):
        self._value["{name}"] = {item}(value)
'''.format(**field)
        acc.append(one)
    code = '\n'.join([klass, init, update, pod] + acc)
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
    'Return code for a sequence type'
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
            val = val._value
        self._value = [{items}(one) for one in val]
'''.format(**ost)
    return klass


class String(BaseType):
    '''
    The oschema string class
    '''
    _value = None

    def __init__(self, val):
        self.update(val)

    def pod(self):
        return self._value

    def __repr__(self):
        if self._value is None:
            return '<string %s: None>' % self.__class__.__name__
        pod = self.pod()
        if len(pod) > 10:
            pod = pod[:10] + "..."
        return '<string %s: %s>' % (self.__class__.__name__, pod)


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
    schema = dict(type="string")
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
    _value = None

    def __init__(self, val):
        self.update(val)

    def pod(self):
        if self._value is None:
            raise ValueError("boolean is unset")
        return True if self._value else False

    def __repr__(self):
        if self._value is None:
            return '<boolean %s: None>' % self.__class__.__name__
        return '<boolean %s: %s>' % (self.__class__.__name__, self.pod())


def boolean_code(**ost):
    'Make a boolean'
    ost.setdefault("doc", "")
    klass = '''
class {name}(Boolean):
    """
    A {name} boolean
    {doc}
    """

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

    def __init__(self, val):
        self.update(val)

    def pod(self):
        return self._value.item()

    def __repr__(self):
        if self._value is None:
            return '<number %s: None>' % self.__class__.__name__
        return '<number %s: %s>' % (self.__class__.__name__, self.pod())


def number_code(**ost):
    'Make a number type'
    klass = '''
class {name}(Number):
    """
    A number type {name}
    """

    def intern(self, val):
        # fixme: add numeric constraints here
        import numpy
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
    ost.setdefault("doc", "")
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
            ind = self._symbols.index(val)
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
    'Return code for an any type'
    ost.setdefault("doc", "")

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
            path, _ = dep.rsplit('.', 1)
            deps.add(f'import {path}')
    deps = list(deps)
    deps.sort()
    return '\n'.join(deps)


def make_source(**ost):
    '''
    Return source code for Python type corresponding to oschema type.
    '''
    coder = globals()["{schema}_code".format(**ost)]
    return deps_code(**ost) + coder(**ost)


def make_code(**ost):
    '''
    Return compiled code for Python type corresponding to oschema type.
    '''
    code = make_source(**ost)
    return compile(code, "<{schema} {name}>".format(**ost), 'exec')


def make_type(**ost):
    '''
    Make a Python type from the oschema.
    '''
    code = make_code(**ost)
    exec(code, globals())
    class_name = ost["name"]
    klass = globals()[class_name]
    path = ost.get("path", None)
    if path:
        mod = module_at(path)
        setattr(mod, class_name, klass)
        klass.__module__ = mod.__name__
    return klass

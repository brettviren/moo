import os
import json
import numpy
from abc import ABC, abstractmethod
from importlib import import_module
from moo.modutil import module_at
from moo.io import load as load_file


def get_deps(deps=None, **ost):
    '''
    Return provided dependencies or calculate based on schema class.
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


def get_type(pathname):
    '''
    Return a type by its fully qualified name
    '''
    if '.' in pathname:
        path, name = pathname.rsplit('.', 1)
        mod = import_module(path)
        return getattr(mod, name)
    return globals()[pathname]


def classify(source, **ost):
    '''
    Turn code into a class
    '''
    source = deps_code(**ost) + '\n' + source
    code = compile(source, "<{schema} {name}>".format(**ost), "exec")
    exec(code, globals())
    class_name = ost["name"]
    cls = globals()[class_name]
    setattr(cls, "_ost", ost)
    path = ost.get("path", None)
    if path:
        mod = module_at(path)
        setattr(mod, class_name, cls)
        cls.__module__ = mod.__name__
    return cls


class BaseType(ABC):

    _value = None

    # Monkey patched by concrete type
    _ost = None

    @abstractmethod
    def pod(self):
        'Return value as plain old data'

    @abstractmethod
    def update(self, *args, **kwds):
        'Update self with new value'

    @property
    def ost(self):
        'The object schema type'
        return dict(self._ost)


class _Record(BaseType):
    '''
    The oschema record class in Python.
    '''

    def __repr__(self):
        return '<record %s, fields: {%s}>' % \
            (self.__class__.__name__, ', '.join(self.field_names))

    def pod(self):
        '''
        Return record as plain old data.

        Will perform validation.
        '''
        # print(self.field_names)
        ret = dict()
        for fname, field in self.fields.items():
            if fname in self._value:
                ret[fname] = getattr(self, fname) # this calls pod() on attr
                continue
            if "default" in field:
                item = get_type(field['item'])
                ret[fname] = item(field['default']).pod()
                continue
            if field.get("optional", False):
                continue
            raise AttributeError("%s missing required field %s" %
                                 (self.__class__.__name__, fname))
        return ret

    def update(self, *args, **kwds):
        '''Update a record.

        An arg in args may be one of:
        - a JSON string
        - a dictionary
        - an instance of a record of same type.

        kwds may be a dictionary.

        Dictionaries are taken to be field settings, values can be POD
        or a typed object consistent with the field type.
        '''
        for arg in args:
            if isinstance(arg, str):
                self._from_string(arg)
            elif isinstance(arg, dict):
                self._from_dict(arg)
            elif isinstance(arg, self.__class__):
                self._from_self(arg)
        if kwds:
            self._from_dict(kwds)

    def _from_string(self, string):
        if not string:
            raise ValueError("attempt to set record %s from empty string" %
                             self.__class__.__name__)
        if string[0] == "{" and string[-1] == "}":
            self._from_dict(json.loads(string))
            return

        raise ValueError("attempt to set record %s with garbage string" %
                         self.__class__.__name__)

    @property
    def field_names(self):
        'Return list of field names'
        return [one['name'] for one in self._ost['fields']]

    @property
    def fields(self):
        'Return mapping of field name to field dict'
        return {one['name']: one for one in self._ost['fields']}

    def _from_dict(self, mapping):
        fields = self.fields
        for fname, fval in mapping.items():
            try:
                field = fields[fname]
            except KeyError:
                # quietly ignore extra values
                continue
            if fval is None:
                fval = field.get("default", None)
            if fval is None:
                optional = field.get("optional", False)
                if optional:
                    continue
            if fval is None:    # 3rd strike
                # generous in what we accept, strict in what we produce
                continue

            # intern as type
            ItemType = get_type(field['item'])

            if isinstance(fval, BaseType) and not isinstance(fval, ItemType) and not issubclass(ItemType, _Any):
                cname = self.__class__.__name__
                tname = type(fval)
                raise ValueError(f'{cname}.{fname}: got {tname}, want {ItemType}')

            self._value[fname] = ItemType(fval)

    def _from_self(self, other):
        # we don't invoke pod() here as we allow incomplete records
        # and pod() will assert completeness.
        fields = self.field_names
        for key, val in other._value.items():
            if key in fields:
                self._value[key] = val

    # baseclass provides __init__, field properties and ._ost


def field_default_value(value, pathname):
    '''
    Return value coerced into type given by pathname
    '''
    if isinstance(value, str):
        if len(value) > 1 and value[0] == "[" and value[-1] == "]":
            # looks like a string rep of list/array
            return value
        if len(value) > 1 and value[0] == "{" and value[-1] == "}":
            # looks like a string rep dict/object
            return value
        # I guess it is a simple string, let Python do some escaping.
        return f'"{value}"'
    # I guess it's a number, array or dict
    return value


def record_class(**ost):
    '''
    Make and return a type corresponding to record object schema type.
    '''
    ost.setdefault("doc", "")
    fields = ost['fields']
    more = dict(
        field_name_list=', '.join(['"{name}"'.format(**f) for f in fields]),
        field_args_fwd=', '.join(['{name}={name}'.format(**f) for f in fields]))
    field_arg_list = list()
    for field in fields:
        field = dict(field)
        field['default'] = field_default_value(field.get('default', None),
                                               field['item'])
        field.setdefault("optional", False)
        one = '{name}:{item} = {default}'.format(**field)
        field_arg_list.append(one)
    more['field_arg_list'] = ', '.join(field_arg_list)
    more.update(ost)

    # make class def + init via compile/exec in order to get rich meta
    # info / docstrings.
    class_source = '''
class {name}(_Record):
    """
    Record type {name} with fields: {field_name_list}

    {doc}
    """

    def __init__(self, *args, {field_arg_list}):
        """
        Create a record type of {name}
        """
        self._value = dict()
        self.update({field_args_fwd})
        self.update(*args)
'''.format(**more)

    acc = list()
    for field in fields:
        one = '''
    @property
    def {name}(self):
        try:
            val = self._value["{name}"]
        except KeyError:
            raise AttributeError("no such attribute {name}")
        return val.pod()

    @{name}.setter
    def {name}(self, value):
        cls = get_type("{item}")
        value = cls(value)
        self._value["{name}"] = value
'''.format(**field)
        acc.append(one)
    source = '\n'.join([class_source] + acc)
    print(source)
    return classify(source, **ost)


class _Sequence(BaseType):

    def __repr__(self):
        return '<sequence %s %d:[%s]>' % \
            (self.__class__.__name__, len(self._value), self.ost['items'])

    def pod(self):
        'Return value as plain old data'
        return [one.pod() for one in self._value]

    def update(self, val):
        'Update self with new value'
        if isinstance(val, str):
            self._from_string(arg)
        elif isinstance(val, self.__class__):
            self._from_list(val._value)
        else:
            self._from_list(val)

    def _from_string(self, string):
        if not string:
            raise ValueError("attempt to set sequence %s from empty string" %
                             self.__class__.name)
        if string[0] == "[" and string[-1] == "]":
            self._from_list(json.loads(string))
        raise ValueError("attempt to set sequence %s with garbage string" %
                         self.__class__.__name__)

    def _from_list(self, lst):
        if not lst:
            self._value = list()
            return
        items = get_type(self.ost['items'])
        self._value = [items(one) for one in lst]

def sequence_class(**ost):
    '''
    Make and return a type corresponding to sequence object schema type.
    '''
    ost.setdefault("doc", "")
    class_source = '''
class {name}(_Sequence):
    """
    A {name} sequence holding type {items}.
    {doc}
    """

    def __init__(self, val):
        """
        Create a sequence type of {name}
        """
        self._value = list()
        self.update(val)
'''.format(**ost)
    return classify(class_source, **ost)


class _String(BaseType):
    '''
    String schema class
    '''

    def __repr__(self):
        if self._value is None:
            return '<string %s: None>' % self.__class__.__name__
        pod = str(self.pod())
        if len(pod) > 10:
            pod = pod[:10] + "..."
        return '<string %s: %s>' % (self.__class__.__name__, pod)

    def pod(self):
        'Return string schema type value as plain old data'
        return self._value

    def update(self, val: str):
        '''
        Update string schema type with a string like val.
        '''
        cname = self.__class__.__name__
        if isinstance(val, self.__class__):
            self._value = val.pod()
            return
        if not isinstance(val, str):
            raise ValueError(f'illegal type for string {cname}: {type(val)}')
        ost = self.ost
        schema = dict(type="string")
        if ost["pattern"]:
            schema["pattern"] = ost["pattern"]
        if ost["format"]:
            schema["format"] = ost["format"]
        from jsonschema import validate as js_validate
        from jsonschema import draft7_format_checker
        from jsonschema.exceptions import ValidationError
        try:
            js_validate(instance=val, schema=schema,
                        format_checker=draft7_format_checker)
        except ValidationError as verr:
            raise ValueError(f'format mismatch for string {cname}') from verr
        self._value = val


def string_class(**ost):
    '''
    Make and return a type corresponding to string object schema type.
    '''
    ost.setdefault("doc", "")
    ost.setdefault("format", None)
    ost.setdefault("pattern", None)
    class_source = '''
class {name}(_String):
    """
    A {name} string type.
    - format : {format}
    - pattern : {pattern}

    {doc}
    """

    def __init__(self, val:str):
        """
        Create a string type {name}.
        """
        self.update(val)
'''.format(**ost)
    return classify(class_source, **ost)


class _Boolean(BaseType):
    '''
    The oschema boolean class
    '''

    def __repr__(self):
        if self._value is None:
            return '<boolean %s: None>' % self.__class__.__name__
        return '<boolean %s: %s>' % (self.__class__.__name__, self.pod())

    def pod(self):
        'Return boolean schema class type as plain old data'
        if self._value is None:
            raise ValueError("boolean is unset")
        return True if self._value else False

    def update(self, val):
        'Update boolean schema class type new boolean like value'
        cname = self.__class__.__name__
        if isinstance(val, self.__class__):
            self._value = self.pod()
            return
        if isinstance(val, bool):
            self._value = val
            return
        if isinstance(val, int):
            self._value = False if val == 0 else True
            return
        if isinstance(val, str):
            if val.lower() in ("yes", "true", "on"):
                self._value = True
            elif val.lower() in ("no", "false", "off"):
                self._value = False
            raise ValueError(f'illegal {cname} boolean string value: {val}')
        raise ValueError(f'illegal {cname} boolean type: {type(val)}')


def boolean_class(**ost):
    '''
    Make and return a type corresponding to boolean object schema type.
    '''
    ost.setdefault("doc", "")
    class_source = '''
class {name}(_Boolean):
    """
    A {name} boolean type.
    {doc}
    """

    def __init__(self, val:bool):
        """
        Create a boolean type {name}.
        """
        self.update(val)
'''.format(**ost)
    return classify(class_source, **ost)


class _Number(BaseType):
    '''
    The oschema number class
    '''
    _eps = 1e-6

    def __repr__(self):
        if self._value is None:
            return '<number %s: None>' % self.__class__.__name__
        return '<number %s: %s>' % (self.__class__.__name__, self.pod())

    def pod(self):
        if self._value is None:
            raise ValueError("number %s is unset" % self.__class__.__name__)
        val = self._value.item()

        # this is pretty sketchy but it's to satisfy issue #11.
        if self._value.dtype == numpy.dtype('f4'):
            return float('%.6e'%val)
        return val

    def update(self, val):
        print(list(self.ost.keys()))
        print(self.ost)
        dtype = self.ost["dtype"]
        dtype = numpy.dtype(dtype)

        cname = self.__class__.__name__

        if type(val) in (int, float, str):
            value = numpy.array(val, dtype)
        elif isinstance(val, self.__class__):
            value = numpy.array(val.pod(), dtype)
        else:
            raise ValueError(f'illegal {cname} number type: {type(val)}')

        nc = self.ost.get("constraints", None)
        if nc:                  # run the gauntlet
            v = value.item()

            mof = nc.get("multipleOf", None)
            if mof is not None:
                if abs(v/mof - int(round(v/mof))) > self._eps:
                    raise ValueError(f'illegal {cname} number {v} not multiple of {mof}')

            emaxi = nc.get("exclusiveMaximum", None)
            if emaxi is not None:
                if not v < emaxi:
                   raise ValueError(f'illegal {cname} number {v} not strictly less than {emaxi}')
               
            emini = nc.get("exclusiveMinimum", None)
            if emini is not None:
                if not v > emini:
                   raise ValueError(f'illegal {cname} number {v} not strictly greater than {emini}')
               
            maxi = nc.get("maximum", None)
            if maxi is not None:
                if not v <= maxi:
                   raise ValueError(f'illegal {cname} number {v} not less than or equal {maxi}')
               
            mini = nc.get("minimum", None)
            if mini is not None:
                if not v >= mini:
                   raise ValueError(f'illegal {cname} number {v} not greater than or equal {mini}')

        self._value = value


def number_class(**ost):
    '''
    Make and return a type corresponding to number object schema type.
    '''
    dtype = ost["dtype"]
    dtype = numpy.dtype(dtype)

    ost.setdefault("doc", "")
    class_source = '''
class {name}(_Number):
    """
    A number type {name} dtype {dtype}
    {doc}
    """

    def __init__(self, val):
        """
        Create a number type {name} dtype {dtype}.
        """
        self.update(val)
'''.format(**ost)
    return classify(class_source, **ost)


class _Enum(BaseType):
    '''
    The oschema enum class
    '''

    def __repr__(self):
        if self._value is None:
            return '<enum {name}: None>'.format(**self.ost)
        return "<enum {name}: '{val}' of {symbols}>".format(val=self._value,
                                                            **self.ost)

    def pod(self):
        if self._value is None:
            raise ValueError("enum %s is unset" % self.__class__.__name__)
        return self._value

    def update(self, val: str = None):
        if isinstance(val, self.__class__):
            self._value = val.pod()
            return
        if val is None:
            self._value = self._ost["default"]
            return
        if isinstance(val, str):
            if val in self._ost['symbols']:
                self._value = val
                return
        cname = self.__class__.__name__
        raise ValueError(f'illegal enum {cname} value {val}')


def enum_class(**ost):
    '''
    Make and return a type corresponding to enum object schema type.
    '''
    ost.setdefault("doc", "")
    class_source = '''
class {name}(_Enum):
    """
    An enum type {name} in {symbols}
    {doc}
    """
    _value = "{default}"

    def __init__(self, val: str = None):
        """
        Create a enum type {name}.
        """
        self.update(val)
'''.format(**ost)
    return classify(class_source, **ost)


class _Any(BaseType):
    '''
    The oschema any class
    '''

    def __repr__(self):
        cname = self.ost['name']
        if self._value is None:
            return f'<any {cname}: None>'
        return f"<any {cname}: {type(self._value)}>"

    def pod(self):
        if self._value is None:
            raise ValueError("any type is unset")
        return self._value.pod()

    def update(self, val):
        if isinstance(val, self.__class__):
            self._value = val._value
            return
        if isinstance(val, _Any):
            raise ValueError("cross Any updates not allowed")
        if isinstance(val, BaseType):
            self._value = val
            return
        cname = self.__class__.__name__
        typ = type(val)
        raise ValueError(f'any type {cname} requires oschema type, got {typ}')


def any_class(**ost):
    '''
    Make and return a type corresponding to any object schema type.
    '''
    ost.setdefault("doc", "")
    class_source = '''
class {name}(_Any):
    """
    An any type {name}.
    {doc}
    """

    def __init__(self, val):
        """
        Create a any type {name}.
        """
        self.update(val)
'''.format(**ost)
    return classify(class_source, **ost)


def make_type(**ost):
    '''
    Make a Python type from the oschema.
    '''
    meth = globals()[ost['schema'] + '_class']
    return meth(**ost)


def make_types(schema):
    '''Make Python types from a schema structure.  

    The schema should be in the form of an array of oschema type
    structures.

    This returns a dict keyed by module + type name and the types will
    also become available via usual Python "import" with their ".path"
    forming the module tree.

    >>> make_types(schema)
    >>> from my.schema.path import MyType
    >>> myobj = MyType()

    '''
    ret = dict()
    for one in schema:
        typ = make_type(**one)
        ret[typ.__module__ + '.' + typ.__name__] = typ
    return ret


def load_types(filename, path=()):
    '''Load Python types from an oschema file.

    The named file may be provided in any format supported by moo.

    See make_types() for more info on resulting types.

    See moo.io.load() for use of "paths".
    '''
    types = load_file(filename, list(path))
    return make_types(types)

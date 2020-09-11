#!/usr/bin/env python3

import numpy
import jsonschema


def validate(value, schema):
    jsonschema.validate(value, schema,
                        format_checker=jsonschema.draft7_format_checker)
    return value


# this holds all known types
known_types = dict()


# it would be nice to use typing.NamedTuple but wanting a base type
# puts the kibosh on that.
class BaseType(object):
    name = None
    doc = ""
    path = ()

    def __init__(self, name=None, doc="", path=()):
        self.name = name
        self.doc = doc
        self.path = [p for p in path if p]
        known_types[self.fqn] = self

    @property
    def deps(self):
        return []

    @property
    def fqnp(self):
        ret = list(self.path)
        ret += [self.name] if self.name else []
        return ret

    @property
    def fqn(self):
        return '.'.join(self.fqnp)

    def to_dict(self):
        return dict(name=self.name,
                    schema=self.schema,
                    path=self.path,
                    doc=self.doc)

    def __str__(self):
        return self.fqn

    def __repr__(self):
        return '<%s "%s">' % (self.__class__.__name__, str(self))

    def __call__(self, val):
        'Return validated value or raise exception'
        ValueError("BaseType called")

    @property
    def schema(self):
        return self.__class__.__name__.lower()


class Boolean(BaseType):
    'A Boolean type'

    js = dict(type="boolean")

    def __call__(self, val):
        if isinstance(val, str):
            if val.lower() in ["true", "yes", "on"]:
                return True
            if val.lower() in ["false", "no", "off"]:
                return False
            raise ValueError(f'unknown boolean string: "{val}"')
        if val:
            return True
        return False


class Number(BaseType):
    'A number type'
    dtype = "i4"

    def __init__(self, name=None, dtype='i4', doc="", path=()):
        super().__init__(name, doc, path)
        self.dtype = dtype

    def to_dict(self):
        d = super().to_dict()
        d.update(dtype=self.dtype)
        return d

    @property
    def js(self):
        dtype = numpy.dtype(self.dtype)
        if dtype.kind == 'f':
            return dict(type="number")
        return dict(type="integer")

    def __call__(self, val):
        validate(val, self.js)
        return numpy.dtype(self.dtype).type(val)


class String(BaseType):
    'A string type'

    pattern = None
    format = None

    def __init__(self, name=None, pattern=None, format=None, doc="", path=()):
        super().__init__(name, doc, path)
        self.pattern = pattern
        self.format = format

    def to_dict(self):
        d = super().to_dict()
        d.update(pattern=self.pattern, format=self.format)
        return d

    @property
    def js(self):
        ret = dict(type="string")
        if self.format:
            ret["format"] = self.format
        if self.pattern:
            ret["pattern"] = self.pattern
        return ret

    def __call__(self, val):
        validate(val, self.js)
        return val

class Sequence(BaseType):
    'A sequence/array/vector type of one type'
    items = None

    def __init__(self, name=None, items=None, doc="", path=()):
        super().__init__(name, doc, path)
        self.items = str(items)

    @property
    def deps(self):
        return [self.items]

    def __repr__(self):
        return '<Sequence "%s" items:%s>' % (str(self), self.items)

    def to_dict(self):
        d = super().to_dict()
        d.update(items = self.items)
        return d

    @property
    def js(self):
        items = known_types[self.items]
        return dict(type="array", items=items.js)

    def __call__(self, val):
        validate(val, self.js)
        items = known_types[self.items]
        return [items(v) for v in val]


class Field(object):
    'A field is NOT a type'
    name = ""
    item = None
    default = None
    doc = ""

    def __init__(self, name=None, item=None, default=None, doc=""):
        self.name = name
        self.item = str(item)
        self.default = default
        self.doc = doc

    def __str__(self):
        return self.name

    def __repr__(self):
        return '<Field "%s" %s [%s]>' % (self.name, self.item, self.default)

    def __call__(self, val):
        item = known_types[self.item]
        return item(val)

class Record(BaseType):
    'A thing with named/typed fields like a struct or a class'
    fields = ()

    def __init__(self, name=None, fields=None, doc="", path=()):
        super().__init__(name, doc, path)
        self.fields = fields

    @property
    def deps(self):
        return [str(f.item) for f in self.fields]

    def to_dict(self):
        d = super().to_dict()
        d.update(fields=[dict(name=f.name, item=f.item) for f in self.fields])
        return d

    def __repr__(self):
        return '<Record "%s" fields:{%s}>' % (str(self),
                                              ", ".join([f.name for f in self.fields]))

    def __getattr__(self, key):
        for f in self.fields:
            if f.name == key:
                return f
        raise KeyError(f'no such field: {key}')

    @property
    def js(self):
        fjs = dict()
        for field in self.fields:
            item = known_types[field.item]
            fjs[field.name] = item.js
        return dict(type="object", properties=fjs)

    def __call__(self, *args, **fields):
        val = dict()
        val.update(*args, **fields)
        validate(val, self.js)
        ret = dict()
        for field in self.fields:
            ret[field.name] = field(val[field.name])
        return ret


class Any(BaseType):

    js = dict()

    def __call__(self, val):
        validate(val, self.js)
        return val


def isin(me, you):
    '''
    Return True if path "you" begins with "me"
    '''
    if not me:
        return True         # I am top namespace
    if not you:
        return False        # I am more specific
    if me[0] != you[0]:
        return False        # We diverge
    return isin(me[0], you[0])


class Namespace(BaseType):

    def __init__(self, name=None, path=(), doc="", **parts):
        n = name.split(".")
        self.name = n.pop(-1)
        self.path = list(path) + n
        self.doc = doc
        self.parts = parts

    def __repr__(self):
        return '<Namespace "%s" parts:{%s}>' % (self, ", ".join(self.parts.keys()))

    def field(self, name, item, default="", doc=""):
        '''
        Make and return a field
        '''
        return Field(name, item, default, doc)

    def normalize(self, key):
        '''
        Normalize a key into this namespace.

        A key may be a sequence or a dot-deliminated string.

        Result is a dot-delim string relative to this namespace.
        '''
        if not isinstance(key, str):
            key = '.'.join(key)
        prefix = str(self) + '.'
        if key.startswith(prefix):
            return key[len(prefix):]
        return key

    def __getitem__(self, key):
        key = self.normalize(key)
        path = key.split(".")
        got = self.parts[path.pop(0)]
        if not path:
            return got
        return got['.'.join(path)]  # sub-namespace

    def _make(self, cls, name, *args, **kwds):
        if "path" not in kwds:
            kwds["path"] = self.fqnp
        ret = cls(name, *args, **kwds)
        self.parts[name] = ret
        return ret

    def __getattr__(self, key):
        try:
            C = schema_class(key)
        except KeyError:
            pass
        else:
            return lambda name, *a, **k: self._make(C, name, *a, **k)

        return self.parts[key]

    def subnamespace(self, subpath):
        '''
        Create a subnamespace.
        '''
        subpath = self.normalize(subpath)
        subpath = subpath.split(".")
        if not subpath:
            return self
        first = subpath.pop(0)
        if first in self.parts:
            ns = self.parts[first]
        else:
            ns = Namespace(first, self.fqnp)
            self.parts[first] = ns
        for sp in subpath:
            ns = ns.namespace(sp)
        return ns

    def isin(self, typ):
        '''
        Return true if type is in this namespace or a subnamespace
        '''
        return isin(self.fqnp, typ.path)

    def add(self, typ):
        '''
        Add type to ns
        '''
        if not self.isin(typ):
            raise ValueError("Not in %r: %r" % (self, typ))
        path = self.normalize(typ.path)
        ns = self.subnamespace(path)
        ns.parts[typ.name] = typ
        return typ
        
    @property
    def deps(self):
        '''
        Return the types used in the immediate namespace (no recursion)
        '''
        return [str(p) for p in self.parts.values()]

    def subns(self, recur=False):
        '''Return array of namespaces in this namespace'''
        ret = []
        for t in self.parts.values():
            if t.schema == "namespace":
                ret.append(t)
                if recur:
                    ret += t.subns(True)
        return ret

    def types(self, recur=False):
        '''Return array of non-namespace types in namespace.  

        Sub-namespaces are not considered types by themselves but if
        recur==True descend into any sub-namespaces and include their
        types.

        '''
        ret = []
        for n,t in self.parts.items():
            if "namespace" == t.schema:
                if recur:
                    ret += t.types(True)
            else:
                ret.append(t)
        return ret
        
    def to_dict(self):
        '''
        Return a dictionary representation of this namespace.
        '''
        d = dict(name=self.name, schema="namespace", path=self.path, doc=self.doc)
        for t in self.parts.values():
            d[t.name] = t.to_dict()
        return d

def schema_class(clsname):
    for cls in [Boolean, Number, String, Record, Sequence, Any, Namespace]:
        if clsname.lower() == cls.__name__.lower():
            return cls
    raise KeyError(f'no such schema class: "{clsname}"')


def from_dict(d):
    '''
    Return a schema object give a dictionary representation as made from .to_dict()
    '''
    d = dict(d)
    schema = d.pop("schema")
    d.pop("deps", None)         # don't care
    name = d.pop("name")
    path = list(d.pop("path"))  # don't abuse input

    if schema == "namespace":
        doc = d.pop("doc", "")
        parts = dict()
        for n, p in d.items():   # rest of d is parts
            parts[n] = from_dict(p)
        return Namespace(name, path, doc, **parts)

    # otherwise make a namespace to hold the building of the type
    if path:
        nsname = path.pop(-1)
        ns = Namespace(nsname, path)
    else:
        ns = Namespace("")
    meth = getattr(ns, schema)
    if schema == "record":      # little help
        fields = [Field(**f) for f in d.pop("fields", [])]
        d["fields"] = fields

    ret = meth(name, **d)
    return ret


def graph(types):
    '''
    Given a list of types, return an object which indexes each type by its fqn
    '''
    ret = dict()
    for t in types:
        ret[t.fqn] = t
    return ret

def toposort(graph):
    '''
    Given a graph of types, return a toplogocal sort of nodes

    Graph is assumed to be an object such as returned by graph()

    https://en.wikipedia.org/wiki/Topological_sorting#Depth-first_search
    '''
    ret = list()
    marks = dict()
    nodes = list(graph.keys())

    def visit(node):
        if node not in graph:
            return

        mark = marks.get(node, None)
        if mark == "perm":
            return
        if mark == "temp":
            raise ValueError("type dependency graph is not a DAG")

        marks[node] = "temp"

        for dep in graph[node].deps:
            visit(dep)
        marks[node] = "perm"
        ret.append(node)

    while nodes:
        visit(nodes.pop(0))
        nodes = [n for n in nodes if n not in marks]

    return ret


def typify(data):
    '''
    Return an array of schema class type objects from array of data structures.

    This simply calls from_dict() on each.
    '''
    return [from_dict(d) for d in data]


def depsort(g):
    '''Given graph g, return dependency-sorted array of its types.'''
    return [g[n] for n in toposort(g)]


def namespacify(data):
    '''Turn array of type data structures into in a namespace hiearchy of
    schema objects based on their paths.

    This is suitable for use with CLI:

        moo [...] render -t moo.oschema.namespacify [...]

    '''
    top = Namespace("")
    for dat in data:
        typ = from_dict(dat)
        top.add(typ)
    return top


def test():
    top = Namespace("top")

    base = top.namespace("base")
    count = base.number("Count", "i4")

    email = base.string("Email", form="email")

    app = top.namespace("app.sub")
    counts = app.sequence("Counts", count)
    app.record("Person", [
        Field("email", email),
        Field("counts", counts)
        ])

    return top


def test2():

    ns = Namespace("foo.bar")
    n1 = ns.number("Count", "i4")
    f1 = ns.field("X",n1)
    f2 = ns.field("L",ns.sequence("LL",n1))
    ns.record("Myobj", [f1,f2])
    ns.to_dict()
    ns2 = ns.namespace("baz")
    ns2.boolean("TF")
    return ns

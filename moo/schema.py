from typing import List
from dataclasses import dataclass, field as dcfield

@dataclass
class Boolean:
    'A Boolean type'
    name: str
    path: List[str] = dcfield(default_factory=list)
    doc: str = ""
    def __repr__(self):
        return '<Boolean "%s">' % (".".join(self.path+[self.name]),)
    
@dataclass
class Number:
    name: str
    dtype: str
    path: List[str] = dcfield(default_factory=list)
    doc: str = ""

    def __repr__(self):
        return '<Number "%s" dtype:%s>' % (".".join(self.path+[self.name]), self.dtype)

@dataclass
class String:
    name: str
    patt: str = ""
    form: str = ""
    path: List[str] = dcfield(default_factory=list)
    doc: str = ""

    def __repr__(self):
        return '<String "%s">' % (".".join(self.path+[self.name]),)

@dataclass
class Sequence:
    name: str
    items: str
    path: List[str] = dcfield(default_factory=list)
    doc: str = ""

    def __repr__(self):
        return '<Sequence "%s" %s>' % (".".join(self.path+[self.name]), self.items)

@dataclass
class Field:
    name: str
    item: str
    default: str = ""
    doc: str = ""

    def __repr__(self):
        return '<Field "%s" %s>' % (self.name, self.item)
    
@dataclass
class Record:
    name: str
    fields: List[Field] = dcfield(default_factory=list)
    path: List[str] = dcfield(default_factory=list)
    doc: str = ""

    def __repr__(self):
        return '<Record "%s" fields:{%s}>' % (".".join(self.path+[self.name]),
                                              ", ".join([f.name for f in self.fields]))
    def __getattr__(self, key):
        for f in self.fields:
            if f.name == key:
                return f
        raise KeyError(f'no such field: {key}')

class Namespace(object):

    def __init__(self, path=[]):
        self._path = path
        if isinstance(path, str) and path:
            self._path = path.split(".")
        self._parts = dict()

    def __repr__(self):
        return '<Namespace "%s" with {%s}>' % (".".join(self._path), ", ".join(self._parts))

    def _make(self, cls, name, *args):
        ret = cls(name, *args)
        self._parts[name] = ret
        return ret

    def number(self, name, dtype, doc=""):
        return self._make(Number, name, dtype, self._path, doc)

    def string(self, name, patt=None, form=None, doc=""):
        return self._make(String, name, patt, form, self._path, doc)

    def integer(self, name, dtype='i4', doc=""):
        return self.number(name, dtype, doc)

    def sequence(self, name, schema, doc=""):
        return self._make(Sequence, name, schema, self._path, doc)

    def record(self, name, fields, doc=""):
        return self._make(Record, name, fields, self._path, doc)

    def __getattr__(self, key):
        return self._parts[key]

    def namespace(self, subpath, doc=""):
        if isinstance(subpath, str) and subpath:
            subpath = subpath.split(".")
        if not subpath:
            return self
        first = subpath.pop(0)
        ns = Namespace(self._path + [first])
        self._parts[first] = ns
        for sp in subpath:
            ns = ns.namespace(sp)
        return ns

        
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

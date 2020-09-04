from typing import List, NamedTuple

class Boolean(NamedTuple):
    'A Boolean type'
    name: str
    path: List[str] = []
    doc: str = ""

    def __str__(self):
        return ".".join(self.path+[self.name])

    def __repr__(self):
        return '<Boolean "%s">' % str(self)

    @property
    def deps(self):
        return []

class Number(NamedTuple):
    'A number type'
    name: str
    dtype: str
    path: List[str] = []
    doc: str = ""

    def __str__(self):
        return ".".join(self.path+[self.name])

    def __repr__(self):
        return '<Number "%s" dtype:%s>' % (str(self), self.dtype)

    @property
    def deps(self):
        return []

class String(NamedTuple):
    name: str
    patt: str = ""
    form: str = ""
    path: List[str] = []
    doc: str = ""

    def __repr__(self):
        return '<String "%s">' % (str(self),)

    def __str__(self):
        return ".".join(self.path+[self.name])

    def __repr__(self):
        return '<String "%s">' % str(self)

    @property
    def deps(self):
        return []

class Sequence(NamedTuple):
    name: str
    items: str
    path: List[str]
    doc: str = ""

    @property
    def deps(self):
        return [str(self.items)]

    def __str__(self):
        return ".".join(self.path+[self.name])

    def __repr__(self):
        return '<Sequence "%s" items:%s>' % (str(self), self.items)

class Field(NamedTuple):
    name: str
    item: str
    default: str = ""
    doc: str = ""

    def __str__(self):
        return self.name

    def __repr__(self):
        return '<Field "%s" %s>' % (self.name, self.item)
    
class Record(NamedTuple):
    name: str
    fields: List[Field] 
    path: List[str]
    doc: str = ""

    @property
    def deps(self):
        return [str(f.item) for f in self.fields]

    def __str__(self):
        return ".".join(self.path+[self.name])

    def __repr__(self):
        return '<Record "%s" fields:{%s}>' % (str(self),
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

    def __str__(self):
        return ".".join(self._path)

    def __repr__(self):
        return '<Namespace "%s" with {%s}>' % (self, ", ".join(self._parts.keys()))

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

    def types(self):
        '''
        Return array of types in namespace, recursively descending.
        '''
        ret = []
        for n,t in self._parts.items():
            if isinstance(t, Namespace):
                ret += t.types()
            else:
                ret.append(t)
        return ret
        
def graph(types):
    '''
    Given a list of types, return an object which indexes each type by its fqn
    '''
    ret = dict()
    for t in types:
        path = '.'.join(t.path + [t.name])
        ret[path] = t
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
        n = nodes.pop(0)
        visit(n)
        nodes = [n for n in nodes if n not in marks]

    return ret;
        
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

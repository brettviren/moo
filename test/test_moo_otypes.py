'''
Test moo.otypes.
'''

import os
import moo
import pytest


def test_junk():
    'Test various stuff about moo.otypes'
    Age = moo.otypes.make_type(name="Age", doc="An age in years", schema="number",
                               dtype='i4', path='a.b')
    a42 = Age(42)
    print(Age, a42)
    a43 = Age(a42)
    del a43

    Person = moo.otypes.make_type(name="Person", doc="A record for a person",
                                  schema="record", path='a.b',
                                  fields=[dict(name="age", item="a.b.Age", default=42)])
    person = Person(age=a42)
    print(Person, person)


def test_with_schema():
    'Test moo.otypes with a schema file'
    here = os.path.dirname(__file__)
    types = dict()
    schemas = moo.io.load(os.path.join(here, "test-ogen-oschema.jsonnet"))
    for one in schemas:
        typ = moo.otypes.make_type(**one)
        tpath = '.'.join(one['path']+[one['name']])
        types[tpath] = typ

    print(list(types.keys()))
    Email = types['app.Email']
    Person = types['app.Person']

    p = Person()
    with pytest.raises(ValueError):
        p.email = "this should fail"
    with pytest.raises(KeyError):
        p.email
    p.email = "brett.viren@gmail.com"
    p.update(counts=(100, 101, 102))
    # An Any must be set with a schema type or the same type of Any
    with pytest.raises(ValueError):
        p.update(affil="bv@bnl.gov")
    p.update(affil=Email("bv@bnl.gov"))
    print(p.pod())

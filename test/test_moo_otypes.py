'''
Test moo.otypes.
'''

import os
import moo
import pytest
from moo.jsonschema import format_checker

def test_junk():
    'Test various stuff about moo.otypes'
    Age = moo.otypes.make_type(
        name="Age", doc="An age in years",
        schema="number", dtype='i4', path='a.b')
    a40 = Age(40)
    print(Age, a40)
    a41 = Age(a40)
    a41.update(41)

    Person = moo.otypes.make_type(
        name="Person", doc="A record for a person",
        schema="record", path='a.b',
        fields=[dict(name="age", item="a.b.Age", default=42)])
    person = Person(age=a40)
    assert isinstance(person, Person)
    import a.b
    assert isinstance(person, a.b.Person)
    print(Person, person)

    print("make a p2 from", person.pod())
    p2 = Person(person)
    assert(p2.age == 40)
    p2.age = 43
    assert(p2.age == 43)

    People = moo.otypes.make_type(
        name="People", doc="A collection or Person items",
        schema="sequence", path="a.b", items='a.b.Person')
    print("p2:", p2.pod())

    pp = People([Person(age=12), Person(age=24)])
    print("pp:", pp.pod())


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
    Affiliation = types['app.Affiliation']

    if format_checker:
        with pytest.raises(ValueError):
            e = Email("this is not an email address and should fail")
            print(f'EMAIL: {e} {repr(e)}')

    p = Person()
    if format_checker:
        with pytest.raises(ValueError):
            p.email = "this should fail"
    with pytest.raises(AttributeError):
        p.email
    p.email = "brett.viren@gmail.com"
    assert p.email == "brett.viren@gmail.com"
    p.update(counts=[100, 101, 102])
    print(p.counts)
    assert p.counts is not None
    # An Any must be set with a schema type or the same type of Any
    with pytest.raises(ValueError):
        p.update(affil="bv@bnl.gov")
    p.update(affil=Email("bv@bnl.gov"))
    print(p.pod())


# pytest -s -k issue_1 test/test_moo_otypes.py
def test_issue_1():
    'Test uknown dtype is caught'
    bad = dict(dtype="u32", schema="number", name="Bad")
    with pytest.raises(TypeError):
        moo.otypes.make_type(**bad)

def test_make_types():
    'Make otypes from array of schema structs'
    schema = [dict(name="Pet", schema="enum",
                   symbols=["cat", "dog", "early personal computer"],
                   default="cat",
                   path="my.home.office",
                   doc="A kind of pet"),
              dict(name="Desk", schema="record",
                   fields=[
                       dict(name="ontop", item="my.home.office.Pet"),
                   ],
                   path="my.home.office",
                   doc="Model my desk")]
    moo.otypes.make_types(schema)

    from my.home.office import Desk, Pet
    desk = Desk(ontop="cat")
    print(desk.pod())
    print(type(desk.ontop), desk.ontop)
    assert desk.ontop == "cat"

def test_issue10():
    '''Check that record field of type string can have empty string as a
    default for issue #10'''
    path = "test.issue10"
    schema = [
        dict(name="Name", schema="string", path=path),
        dict(name="YN", schema="boolean", path=path),
        dict(name="Thing", schema="record",
             fields=[
                 dict(name="name", item=path+".Name", default=""),
                 dict(name="yn", item=path+".YN", default=False),
             ], path=path),
    ]
    moo.otypes.make_types(schema)
    from test.issue10 import Thing
    thing = Thing()
    print(thing.pod())

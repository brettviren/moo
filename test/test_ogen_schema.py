import os
import moo
import pytest

def test_load_types():
    'Load an oschema, make types'
    here = os.path.dirname(__file__)
    print(f'include in path: {here}')

    moo.otypes.make_type(schema="string", name="Uni", path="test.basetypes")
    from test.basetypes import Uni

    types = moo.otypes.load_types("test-ogen-oschema.jsonnet", [here])
    from app import Person, Affiliation

    per = Person(email="foo@example.com", counts=[42],
                 affil=Uni("Snooty U"), mbti="judging")
    print(per)
    assert per.counts[0] == 42
    print(per.affil)


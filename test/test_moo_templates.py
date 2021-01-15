import pytest
from moo.templates.util import listify, relpath

def test_listify():
    assert [] == listify("")
    assert [] == listify([])
    assert ["foo"] == listify("foo")
    assert ["foo"] == listify(["foo"])
    assert ["foo", "bar"] == listify(["foo","bar"])
    assert ["foo", "bar"] == listify("foo.bar")

def test_relpath():
    'Check relpath()'
    assert len(relpath("foo.bar", "foo.bar")) == 0
    assert ["foo"] == relpath("foo", "")
    assert ["foo","bar"] == relpath("foo.bar", "")
    assert ["bar"] == relpath("foo.bar", "foo")
    assert ["bar"] == relpath("foo.bar", "foo.baz")


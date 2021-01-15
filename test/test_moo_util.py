import pytest
from moo.util import resolve, select_path, validate, clean_paths, graft
from jsonschema.exceptions import ValidationError
from jsonpointer import JsonPointerException


def test_resolve():
    'Check file resolving'
    assert resolve("/tmp", ("/")) == "/tmp"
    with pytest.raises(ValueError):
        resolve("does-not-exist")


def test_select_path():
    'Check data path selection'
    data = dict(a=42, b=dict(c=[1, 2, 3]))
    assert select_path(data, "a") == 42
    assert select_path(data, "b.c.2") == 3
    with pytest.raises(KeyError):
        select_path(data, "dne")


def test_validate():
    'Check validation method'
    with pytest.raises(ValueError):
        validate(None, None, "dne")

    validate("hello", dict(type="string"))
    validate("1234", dict(type="string", pattern="^[0-9]+$"))
    validate("me@example.com", dict(type="string", format="email"))
    with pytest.raises(ValidationError):
        validate("1234", dict(type="string", format="email"))
    with pytest.raises(ValidationError):
        validate("wrong", dict(type="number"))


def test_clean_paths():
    'Check clean paths'
    paths = clean_paths("some-file")
    assert len(paths) == 2


def test_graft():
    'Check graft'
    obj = graft(dict(), "/a", 2)
    with pytest.raises(JsonPointerException):
        obj = graft(obj, "/b/c", 42)
    assert obj["a"] == 2


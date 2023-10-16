import pytest

from moo.ovalid import validate, ValidationError

def test_regex():
    'Check validation method'

    js = {"$schema": "http://json-schema.org/draft-07/schema#"}

    validate("hello", dict(js, type="string"))
    validate(1234, dict(js, type="number"))
    validate("1234", dict(js, type="string", pattern="^[0-9]+$"))

    validate("127.0.0.1", dict(js, type="string", 
                               pattern = '[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}'))
    with pytest.raises(ValidationError):
        validate("& not @ ip", dict(js, type="string",
                               pattern = '[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}'))

    validate("127.0.0.1", dict(js, type="string", format="ipv4"))
    with pytest.raises(ValidationError):
        validate("& not @ ip", dict(js, type="string", format="ipv4"))

    # https://github.com/python-jsonschema/jsonschema/issues/403
    with pytest.raises(ValidationError):
        validate("1;2;3#4", dict(js, type="string", format="email"))

    with pytest.raises(ValidationError):
        validate(1234, dict(js, type="string"))

    with pytest.raises(ValidationError):
        validate("wrong", dict(js, type="number"))


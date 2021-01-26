#!/usr/bin/env pytest
import os
import pytest
import moo.otypes
tdir = os.path.dirname(os.path.abspath(__file__))
moo.io.default_load_path = (tdir,)

moo.otypes.load_types("issue13-schema.jsonnet");
from test.issue13 import Object, Count, Counts, CountsObject

def test_correct_usage():
    o1 = Object(rname="rname", rany=Count(1))
    assert(hasattr(o1, "rname"))
    assert(hasattr(o1, "rany"))
    print(o1)
    print(o1.pod())
    assert(o1.rname == "rname")
    assert(o1.rany == 1)
    assert(not hasattr(o1, 'oname'))
    assert(not hasattr(o1, 'oany'))
    assert(o1.dname == "")


def test_fails_when_missing_required():
    o1 = Object()
    with pytest.raises(AttributeError):
        print(o1.pod())
    o1.rname = "rname"
    o1.rany = Count(1)
    print(o1.pod())

def test_provide_optional():
    o1 = Object(rname="rname", rany=Count(1),
                oname="oname", oany=Count(2))
    assert(hasattr(o1, "rname"))
    assert(o1.rname == "rname")
    assert(hasattr(o1, "rany"))
    assert(o1.rany == 1)
    assert(hasattr(o1, "oname"))
    assert(o1.oname == "oname")
    assert(hasattr(o1, "oany"))
    assert(o1.oany == 2)

def test_hidden_attrerr():

    co = CountsObject()
    with pytest.raises(AttributeError):
        # incomplete object can not finalize!
        co.pod()

    o1 = Object(rname="rname", rany=Count(1),
                oany=CountsObject())
    with pytest.raises(AttributeError):
        o1.pod()

    co.counts = [Count(3)]
    print(co.pod())

    # note, o1 is still incomplete as co was effectively passed by
    # value and fixing its co.counts above does not help the copy
    # inside o1.  We must re-set o1.oany to the fixed value before
    # o1.pod() can succeed.  Basically, it's pointless to want to pass
    # an incomplete record as a field to another record.  Of coures,
    # moo.otypes should correctly tell the developer of their error
    # which is what #13 is about!

    o1.oany = co
    print(o1.pod())

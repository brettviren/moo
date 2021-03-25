#!/usr/bin/env pytest

import os
import pytest
import moo.io
from moo.otypes import load_types, make_type
tdir = os.path.dirname(os.path.abspath(__file__))

def test_issue27():
    sfile = os.path.join(tdir, 'issue27-schema.jsonnet')
    moo.otypes.load_types(sfile)
    from issue27 import ConfParams

    good = ConfParams()
    assert good.trigger_interval_ticks == 64000000

    good2 = ConfParams(trigger_interval_ticks=10)

    with pytest.raises(ValueError): 
        # must be greater or equal to 10
        r = ConfParams(trigger_interval_ticks=0)

def test_mof():
    Evens=make_type(name="Evens", schema="number", dtype="f4",
                    constraints=dict(multipleOf=2))
    e1 = Evens(4)
    e1.update(10)

    with pytest.raises(ValueError):
        e2 = Evens(3)
    with pytest.raises(ValueError):
        e1.update(1.0)
        
def test_mm():
    MM = make_type(name="MM", schema="number", dtype="f8",
                   constraints=dict(maximum=10, minimum=-10))
    MM(10)
    MM(-10)
    MM(0)

    v = 5
    mm = MM(v)
    assert mm.pod() == v
    assert mm.pod() <= 10
    assert mm.pod() >= -10

    with pytest.raises(ValueError):
        v = 10.00001
        mm = MM(v)
    with pytest.raises(ValueError):
        MM(-10.00001)

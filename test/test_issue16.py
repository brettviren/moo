#!/usr/bin/env pytest

import os
import pytest
import moo.otypes
tdir = os.path.dirname(os.path.abspath(__file__))
moo.io.default_load_path = (tdir,)

moo.otypes.load_types("issue16-schema.jsonnet");
from test.issue16 import A, B, AB

def test_correct_usage():
    ab = AB(a=A(), b=B())
    print("correct usage:", ab.pod())
    
def test_swapped_types():
    with pytest.raises(ValueError):
        ab = AB(a=B(), b=A())

    

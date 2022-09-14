#!/usr/bin/env python

import os
import moo

here = os.path.dirname(__file__)
moo.io.default_load_path = [here]

def test_with_ab():
    moo.otypes.load_types("./issue16-schema.jsonnet")
    from test.issue16 import A, B, AB
    ab = AB(a=A(), b=B())
    #print(type(ab), type(ab.a), type(ab.b))
    assert not isinstance(type(ab), dict)
    assert isinstance(ab.a, dict)

    

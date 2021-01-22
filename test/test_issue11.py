#!/usr/bin/env python3

import os
import moo.otypes

tdir = os.path.dirname(os.path.abspath(__file__))
moo.io.default_load_path = (tdir,)

def test_float():
    moo.otypes.load_types("issue11-schema.jsonnet");
    from test.issue11 import Float, Double

    for x in [0.9, 0.8, 0.000000000000012,
              -0.9, -0.8, -0.000000000000012]:

        dx = Double(x).pod()
        ddx = dx-x
        print(dx, ddx)
        assert(dx == x)
        assert(ddx == 0.0)    

        fx = Float(x).pod()
        dfx = fx-x
        print(fx, dfx)
        assert(fx == x)
        assert(dfx == 0.0)    

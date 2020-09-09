#!/usr/bin/env python3
import sys
import moo.io as mio
import moo.util as mu
import moo.oschema as ms

fname = mu.resolve(sys.argv[1])
dat = mio.load(fname)
assert(dat)
for d in dat:
    s = ms.from_dict(d)
    d2 = s.to_dict()
    print(f'data in:\n\t{d}\nobject:\n\t{s!r}\ndata out:\n\t{d2}')

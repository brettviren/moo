local moo = import "moo.jsonnet";

moo.method("open", moo.types.bool, false, [
    moo.attribute("door", moo.types.str),
    moo.attribute("code", moo.types.int, 1234)],
           "Open a door with a code, return true if successful")

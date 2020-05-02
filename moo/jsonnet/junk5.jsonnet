local moo = import "moo.jsonnet";
local lang = import "moo/cpp.jsonnet";
moo.method("open", lang.types.boolean, false, [
    moo.attribute("door", lang.types.string),
    moo.attribute("code", lang.types.integer, 1234)],
          "Open a door with a code")

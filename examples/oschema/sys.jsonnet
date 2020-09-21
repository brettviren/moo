// examples/oschema/sys.jsonnet
local moo = import "moo.jsonnet";
local sys = moo.oschema.schema("sys");
moo.oschema.sort_select([
    sys.number("Count", "u4")
])

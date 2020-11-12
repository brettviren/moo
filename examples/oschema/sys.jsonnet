// examples/oschema/sys.jsonnet
local moo = import "moo.jsonnet";
local sys = moo.oschema.schema("sys");
[sys.number("Count", "u4")]


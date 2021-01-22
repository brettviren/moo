local moo = import "moo.jsonnet";
local as = moo.oschema.schema("test.issue11");
[as.number("Float", dtype='f4'), as.number("Double", dtype='f8')]

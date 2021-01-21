local moo = import "moo.jsonnet";
local s = moo.oschema.schema("issue12");
[s.enum("Fruit", ["apple", "orange"])]

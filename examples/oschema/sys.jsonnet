// examples/oschema/sys.jsonnet
local oschema = import "oschema.jsonnet";
local sys = oschema.schema("sys");
oschema.sort_select([
    sys.number("Count", "u4")
])

local moo = import "moo.jsonnet";
local as = moo.oschema.schema("ovalid.atomic");
{
    model: 42,
    target: as.number("Count", dtype="u4")
}

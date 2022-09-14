local moo = import "moo.jsonnet";
local as = moo.oschema.schema("ovalid.atomic");
local context = {
    name: as.string("Name"),
    count: as.number("Count", dtype="u4"),
    real: as.number("Real", dtype="f4"),
};
{
    context: context,
    models: ["moo", 42, 3.1415, "NaN"],
    targets: ["Name", "count", "Real", "Count"],
}

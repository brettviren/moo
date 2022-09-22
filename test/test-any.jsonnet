local moo = import "moo.jsonnet";
local as = moo.oschema.schema("test.any");

{
    context: {derp: as.any("Anything") },
    targets: ["derp","derp"],
    models: [42, {what:"anything"}],
}

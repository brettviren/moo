// make some objects that can be validated against schema in anys.jsonnet
local moo = import "moo.jsonnet";
local schema = import "anys.jsonnet";
local types = {[s.name]:s for s in schema};
local json_schema_id = "https://brettviren.github.io/moo/examples/oschema/anys.json";
local jschema = moo.jschema.convert(schema, json_schema_id);

local email = "user@example.com";
local num = 42;

local mktest(tname, data) = {
    valid: jschema { "$ref": "#/definitions/anys/"+tname },
    model: data
};
local listify = function(tests) {
        valid: [one.valid for one in tests],
        model: [one.model for one in tests],
};

local passes = [
    mktest("VoidStar", email),
    mktest("VoidStar", num),

    mktest("OneNumOrEmail", email),
    mktest("OneNumOrEmail", num),
    mktest("AnyNumOrEmail", email),
    mktest("AnyNumOrEmail", num),
];
local fails = [
    mktest("AllNumOrEmail", email),
    mktest("AllNumOrEmail", num),

];

{
    pass: listify(passes),
    fail: listify(fails),
}

// all-in-one schema + omodel to test possible bugs related to paths
// things you can do with this file
// $ moo compile test/test-schema-template-path.jsonnet
// $ moo -D model render test/test-schema-template-path.jsonnet ostructs.hpp.j2
// $ moo -D model1 render test/test-schema-template-path.jsonnet ostructs.hpp.j2
// $ moo -D model2 render test/test-schema-template-path.jsonnet ostructs.hpp.j2
// etc with onljs.hpp.j2.

local moo = import "moo.jsonnet";
local ctxpath = ["test","schema"];
local listpath = ctxpath + ["template","path"];
local dotpath=std.join(".", listpath);
local s1 = moo.oschema.schema(dotpath + ".schema1");
local s2 = moo.oschema.schema(dotpath + ".schema2");
local hier = {
    // schema 1 types
    email: s1.string("Email", format="email", doc="Electronic mail address"),
    watev: s1.any("Whatever"),

    // schema 2 types
    count: s2.number("Count", "u4"),
    thing: s2.record("Thing", [
        s2.field("count", self.count),
        s2.field("email", self.email),
    ]),
};
local sa = moo.oschema.sort_select(hier);

local ocpp = import "ocpp.jsonnet";
local omodel = import "omodel.jsonnet";

{
    schema: sa,
    model: omodel(sa, listpath, ctxpath) { lang: ocpp },
    model1: omodel(sa, listpath+["schema1"], ctxpath) { lang: ocpp },
    model2: omodel(sa, listpath+["schema2"], ctxpath) { lang: ocpp },
}

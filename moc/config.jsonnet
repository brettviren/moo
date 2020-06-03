// This document defines a suite of configuration objects that follow
// the moc schema.

local moo = import "moo.jsonnet";
local moc = import "schema.jsonnet";
local mt = moc.types;

{
    schema: moo.schema.object({
        apps:moo.schema.array(moc.schema.application)}, ["apps"]),
                              

    model: {
        apps: [
            mt.application("app1", components = [
                mt.test_source("ts1", 10, ["src1"]),
            ], portset = [
                mt.port("src1", "push", mt.connect_auto("app2","snk1"))
            ])
        ]
    }
    

}

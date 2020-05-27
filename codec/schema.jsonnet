local moo = import "moo.jsonnet";
local ms = moo.schema;
local mt = moo.types;
{
    ident: ms.string(),
    body: ms.jsonschema(),
    mtype: ms.object({ident:$.ident,body:$.body}, ["ident"]),
    codec: ms.array($.mtype),

    schema : std.prune($.codec),

    types :: mt + {
        timestamp: { issued: mt.timestamp("i8", "ms")},
        mtype(name,body):: {ident:name, body:body },
    }
}

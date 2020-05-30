local moo = import "moo.jsonnet";
local ms = moo.schema;
local mt = moo.types;
{
    ident: ms.string(),
    body: ms.jsonschema(),
    mtype: ms.object({ident:$.ident,body:$.body}, ["ident"]),
    codec: ms.object({
        // An codec has a location.
        namepath: ms.array(ms.string()),
        // and a set of message types.
        mtypes: ms.array($.mtype),
    }),

    schema : std.prune($.codec),

    types :: mt + {
        timestamp: { issued: mt.timestamp("i8", "ms")},
        mtype(name,body):: {ident:name, body:body },
    }
}

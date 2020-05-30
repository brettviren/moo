local codec = import "codec/schema.jsonnet";
local ct = codec.types;

// This model wants every message type to carry some common fields
local mtype(ident, payload={}) = ct.mtype(ident, ct.timestamp + payload);

{
    namepath: ["ccm"],
    mtypes: std.prune([
        mtype("config", {role:ct.str(), cfgid: ct.str()}),
        mtype("start"),
        mtype("stop"),
        mtype("log", {level: ct.str(), message: ct.str()}),
    ])
}

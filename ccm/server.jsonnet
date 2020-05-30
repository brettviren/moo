local codec = import "codec/schema.jsonnet";
local ct = codec.types;
local parent = import "model.jsonnet";
local cfg = parent.mtypes[0];

cfg {
    body: super.body {
        favorite_color: ct.str(def="purple"),
    }
}

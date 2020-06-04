// model component config structure
local moo = import "moo.jsonnet";
local ms = moo.schema;

local cc(namepath, config) :: {
    namepath:namepath, config:config
};

[
    cc(["moc","demo","source"], {
        ntosend: ms.integer()
    })
]

// model component configuration objects
local moo = import "moo.jsonnet";
local ms = moo.schema;

local cc(namepath, config) = ms.object({
  namepath:namepath,
  config:config
});

[
    cc(["moc","demo","source"], {
        ntosend: ms.integer()
    })
]

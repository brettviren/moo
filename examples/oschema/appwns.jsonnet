// examples/oschema/app.jsonnet
local oschema = import "oschema.jsonnet";
local sysns = oschema.namespace("sys", import "sys.jsonnet");
local appns = oschema.namespace("app", import "app.jsonnet");
local topns = oschema.namespace("", [sysns,appns]);
topns


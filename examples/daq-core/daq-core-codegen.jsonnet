local moo = import "moo.jsonnet";
local dcs = import "daq-core-schema.jsonnet";
moo.schema.avro.codegen("corecfg", dcs, "daqcfg")

local moo = import "moo.jsonnet";
local ns = "issue27";
local s = moo.oschema.schema(ns);
local nc = moo.oschema.numeric_constraints;

local types = {
  trigger_interval: s.number("trigger_interval", dtype="i8", constraints=nc(minimum=10)),

  conf : s.record("ConfParams", [
    s.field("trigger_interval_ticks", self.trigger_interval, 64000000,
      doc="Interval between triggers in 16 ns time ticks (default 1.024 s) ")])
};

moo.oschema.sort_select(types, ns)

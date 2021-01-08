local moo = import "moo.jsonnet";
// A schema builder in the given path (namespace)
local ns = "dunedaq.readout.datalinkhandler";
local s = moo.oschema.schema(ns);
// Object structure used by the test/fake producer module
local datalinkhandler = {
  size: s.number("Size", "u8",
          doc="A count of very many things"),
  count : s.number("Count", "i4",
           doc="A count of not too many things"),
  pct : s.number("Percent", "f4",
          doc="Testing float number"),
  str : s.string("Str", "string",
          doc="A string field"),
  trfa : s.boolean("trfa"),
  conf: s.record("Conf", [
    s.field("raw_type", self.str, "wib",
        doc="Raw type"),
    s.field("source_queue_timeout_ms", self.count, 2000,
        doc="Timeout for source queue"),
    s.field("latency_buffer_size", self.size, 100000,
        doc="Size of latency buffer"),
    s.field("pop_limit_pct", self.pct, 0.5,
        doc="Latency buffer occupancy percentage to issue an auto-pop"),
    s.field("pop_size_pct", self.pct, 0.8,
        doc="Percentage of current occupancy to pop from the latency buffer"),
    s.field("fake_trigger", self.trfa, false,
        doc="Do we generate false triggers?")
  ], doc="Generic readout element configuration"),
};
moo.oschema.sort_select(datalinkhandler, ns)

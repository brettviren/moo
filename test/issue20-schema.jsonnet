local moo = import "moo.jsonnet";
// A schema builder in the given path (namespace)
local ns = "test";
local s = moo.oschema.schema(ns);
local test = {
    bool_data: s.boolean("BoolData", doc="A bool"),
    int_data: s.number("IntData", dtype="i4"),
    a_record: s.record("ARecord", [
        s.field("a_field", self.bool_data, false,
                doc="A test field"),
        s.field("b_field", self.int_data, false, // (sic, test coercion)
                doc="Another test field"),
    ], doc="Test record"),
};
// Output a topologically sorted array.
moo.oschema.sort_select(test, ns)

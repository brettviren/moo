local moo = import "moo.jsonnet";
local as = moo.oschema.schema("test.issue16");
local hier = {
    name: as.string("Name"),
    count: as.number("Count", dtype="u4"),

    a: as.record("A", [ as.field("name", self.name, default="name") ]),
    b: as.record("B", [ as.field("count", self.count, default=42) ]),

    ab: as.record("AB", [ as.field("a", self.a),
                          as.field("b", self.b)]),
};
moo.oschema.sort_select(hier)

local moo = import "moo.jsonnet";
local as = moo.oschema.schema("ovalid.simple");
{
    name: as.string("Name"),
    count: as.number("Count", dtype="u4"),
    real: as.number("Real", dtype="f4"),
    any: as.any("Data"),

    obj: as.record("Object", [
        as.field("rname", self.name, doc="required string"),
        as.field("rany", self.any, doc="required any"),
        as.field("oname", self.name, optional=true, doc="optional string"),
        as.field("oany", self.any, optional=true, doc="optional any"),                
        as.field("dname", self.name, default="", doc="default string"),
        ///NOTE: can not currently provide a default to an any!
        //as.field("dany", self.any, default=???, doc="default any"),
    ]),

    counts: as.sequence("Counts", self.count),
    cobj: as.record("CountsObject", [
        as.field("counts", self.counts),
    ]),

}


// examples/oschema/app.jsonnet
local moo = import "moo.jsonnet";
local sa = import "sys.jsonnet";
local sh = moo.oschema.hier(sa);
local as = moo.oschema.schema("app");
local hier = {
    counts: as.sequence("Counts",sh.sys.Count,
                        doc="All the counts"),

    email: as.string("Email", format="email",
                    doc="Electronic mail address"),
    affil: as.any("Affiliation",
                  doc="An associated object of any type"),
    mbti: as.enum("MBTI",["introversion","extroversion",
                          "sensing","intuition",
                          "thinking","feeling",
                          "judging","perceiving"]),
    make: as.string("Make"),
    model: as.string("Model"),
    autotype: as.enum("VehicleClass", ["boring", "fun"]),
    vehicle : as.record("Vehicle", [
        as.field("make", self.make, default="Subaru"),
        as.field("model", self.model, default="WRX"),
        as.field("type", self.autotype, default="fun")]),

    person: as.record("Person", [
        as.field("email",self.email,
                 doc="E-mail address"),
        as.field("email2",self.email,
                 doc="E-mail address", default="me@example.com"),
        as.field("counts",self.counts,
                 doc="Count of some things"),
        as.field("counts2",self.counts,
                 doc="Count of some things", default=[0,1,2]),
        as.field("affil", self.affil,
                 doc="Some affiliation"),
        as.field("mbti", self.mbti,
                 doc="Personality"),
        as.field("vehicle", self.vehicle, doc="Example of nested record"),
        as.field("vehicle2", self.vehicle, default={model:"CrossTrek", type:"boring"},
                 doc="Example of nested record with default"),
        as.field("vehicle2", self.vehicle, default={model:"BRZ"},
                 doc="Example of nested record with default"),
    ], doc="Describe everything there is to know about an individual human"),
};
// moo.oschema.sort_select(hier, "app")
sa + moo.oschema.sort_select(hier)






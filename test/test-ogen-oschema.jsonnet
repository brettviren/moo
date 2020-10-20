// examples/oschema/app.jsonnet
local moo = import "moo.jsonnet";
local as = moo.oschema.schema("app");
local hier = {
    count: as.number("Count", "u4"),
    counts: as.sequence("Counts", self.count,
                        doc="All the counts"),

    email: as.string("Email", format="email",
                    doc="Electronic mail address"),
    affil: as.any("Affiliation",
                  doc="An associated object of any type"),
    mbti: as.enum("MBTI",["introversion","extroversion",
                          "sensing","intuition",
                          "thinking","feeling",
                          "judging","perceiving"]),
    person: as.record("Person", [
        as.field("email",self.email,
                 doc="E-mail address"),
        as.field("counts",self.counts,
                 doc="Count of some things"),
        as.field("affil", self.affil,
                 doc="Some affiliation"),
        as.field("mbti", self.mbti,
                 doc="Personality"),
    ], doc="Describe everything there is to know about an individual human"),
};
moo.oschema.sort_select(hier, "app")







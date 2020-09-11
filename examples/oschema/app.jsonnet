// examples/oschema/app.jsonnet
local oschema = import "oschema.jsonnet";
local sh = oschema.hier(import "sys.jsonnet");
local as = oschema.schema("app");
local hier = {
    email: as.string("Email", format="email",
                    doc="Electronic mail address"),
    affil: as.any("Affiliation",
                  doc="An associated object of any type"),
    person: as.record("Person", [
        as.field("email",self.email,
                 doc="E-mail address"),
        as.field("counts",self.counts,
                 doc="Count of some things"),
        as.field("affil", self.affil,
                 doc="Some affiliation"),
    ], doc="Describe everything there is to know about an individual human"),
    counts: as.sequence("Counts",sh.sys.Count,
                        doc="All the counts"),
};
oschema.sort_select(hier, "app")







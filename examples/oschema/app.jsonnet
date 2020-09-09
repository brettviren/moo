// examples/oschema/app.jsonnet
local oschema = import "oschema.jsonnet";
local sh = oschema.hier(import "sys.jsonnet");
local as = oschema.schema("app");
local hier = {
    email: as.string("Email", format="email"),
    person: as.record("Person", [
        as.field("email",self.email),
        as.field("counts",self.counts)
    ]),
    counts: as.sequence("Counts",sh.sys.Count),
};
oschema.sort_select(hier, "app")







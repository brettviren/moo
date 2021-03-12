// Schema describing elements of a boot command

local moo = import "moo.jsonnet";
local re = moo.schema.re;
local s = moo.oschema.schema("still.boot");
local nc = moo.oschema.numeric_constraints;

local hier = {
    string: s.string("String", doc="A string"),
    ident: s.string("Ident", pattern=re.ident_only,
                    doc="Identify something by name"),
    count: s.number("Count", dtype="u4",
                    constraints=nc(minimum=0),
                    doc="A count of something"),

    role: s.enum("Role",
                 symbols=["appfwk", "rc", "webui", "zoned", "zzz"],
                 default="appfwk",
                 doc="Known job roles"),
    roles: s.sequence("Roles", self.role, doc="Sequence of job roles"),

    param: s.record("Parameter", [
        s.field("key", self.ident, doc="Key name of parameter"),
        s.field("value", self.string, doc="Value of parameter"),
    ], doc="Free form key/value parameter"),
    params: s.sequence("Parameters", self.param),

    job: s.record("Job", [
        s.field("ident", self.ident, doc="Identify job within boot"),
        s.field("roles", self.roles, doc="Roles this job plays"),
        s.field("cardinality", self.count, doc="Number of tasks from this job"),
        s.field("parameters", self.params, doc="Role parameters"),
    ], doc="A job abstractly defines some intended running state"),
    jobs: s.sequence("Jobs", self.job, doc="Set of jobs"),

    boot: s.record("Boot", [
        s.field("ident", self.ident, doc="Identify the partition to boot"),
        s.field("jobs", self.jobs, doc="Jobs making up the partition"),
    ], doc="Information needed to realize a DAQ partition"),

};
moo.oschema.sort_select(hier, "still.boot")

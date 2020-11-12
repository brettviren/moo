import moo.oschema as mo
import systypes

ss = {typ.name.lower(): typ for typ in systypes.schema}

ns = mo.Namespace("app")

counts = ns.sequence("Counts", ss['count'])
email = ns.string("Email", format="email",
                  doc="Electronic mail address")
affil = ns.any("Affiliation",
               doc="An associated object of any type")
mbti = ns.enum("MBTI", ["introversion", "extroversion",
                        "sensing", "intuition",
                        "thinking", "feeling",
                        "judging", "perceiving"])

make = ns.string("Make")
model = ns.string("Model")
autotype = ns.enum("VehicleClass", ["boring", "fun"])
vehicle = ns.record("Vehicle", [
    ns.field("make", make, default="Subaru"),
    ns.field("model", model, default="WRX"),
    ns.field("type", autotype, default="fun")])


person = ns.record("Person", [
    ns.field("email", email, doc="E-mail address"),
    ns.field("email2", email, doc="E-mail address", default="me@example.com"),
    ns.field("counts", counts, doc="Count of some things"),
    ns.field("counts2", counts, doc="Count of some things", default=[0, 1, 2]),
    ns.field("affil", affil, doc="Some affiliation"),
    ns.field("mbti", mbti, doc="Personality"),
    ns.field("vehicle", vehicle, doc="Example of nested record"),
    ns.field("vehicle2", vehicle, default=dict(model="CrossTrek", type="boring"),
             doc="Example of nested record with default"),
    ns.field("vehicle2", vehicle, default=dict(model="BRZ"),
             doc="Example of nested record with default"),
], doc="Describe everything there is to know about an individual human")


schema = systypes.schema + mo.depsort({k: v for k, v in globals().items() if isinstance(v, mo.BaseType)})

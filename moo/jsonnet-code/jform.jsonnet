// support for converting oschema to ulion/jsonform 
//
// This differs from JSON Schema mad eby jschema.jsonnet:
//
// - jsonform does not like $ref.
// 
// - no $id or $schema
//
// - put it all under a top level .schema attribute
//
// - jsonform will use an optional top-level .form attribute
//
// - title and description attributes will be honored which this
// provides from name and doc respectively.

local moo = import "moo.jsonnet";
local isr(x,r) = if std.type(x) != "null" then r;

local maybe(obj, key, def=null) = if std.objectHas(obj, key) then obj[key] else def;

local select(obj, keys) = {
    [if std.objectHas(obj, k) then k]:obj[k] for k in keys
};

{
    dtypes: {                  // fixme: add these as default while honor only one min/max
        i8: { type:"integer"}, // maximum: std.pow(2,63)-1, minimum: -std.pow(2,63) },
        i4: { type:"integer"}, // maximum: std.pow(2,31)-1, minimum: -std.pow(2,31) },
        i2: { type:"integer"}, // maximum: std.pow(2,15)-1, minimum: -std.pow(2,15) },
        u8: { type:"integer"}, // minimum: 0, maximum: std.pow(2,64)-1 },
        u4: { type:"integer"}, // minimum: 0, maximum: std.pow(2,32)-1 },
        u2: { type:"integer"}, // minimum: 0, maximum: std.pow(2,16)-1 },
        f4: { type:"number" },
        f8: { type:"number" },
    },

    // jsonform allows extra bits
    jform(s) :: {
        title: s.name,
        [isr(maybe(s, "doc"), "description")]: s.doc
    },

    boolean(s, hier) :: self.jform(s) {
        type:"boolean",
    },

    number(s, hier) :: self.jform(s)
        + self.dtypes[s.dtype] + maybe(s, "constraints", {}),

    string(s, hier) :: self.jform(s) {
        type: "string",
    } + select(s, ["format","pattern"]),

    sequence(s, hier) :: self.jform(s) {
        type: "array",
        items: $.type(hier[s.items], hier),
    },

    field(f, hier) :: $.type(hier[f.item], hier) + self.jform(f) + {
        [isr(maybe(f, "default"),"default")]: f.default,
    },

    record(s, hier) :: self.jform(s) {
        type: "object",
        properties: {
            [f.name]: $.field(f, hier) for f in s.fields
        }
    },
    
    // note, enum need not be string type but here we force it
    enum(s, hier) :: self.jform(s) {
        type: "string",
        enum: s.symbols
    },

    // JSON Schema doesn't have a pure "any" type but an "empty"
    // schema is effectively equivalent.  What sane thing can we do
    // for jsonform?
    any(a, hier) :: self.jform(a) {
        type: "any",
    },

    // Boolean combos
    xxxOf(of, a, hier) :: self.jform(a) {
        [of] : [$.type(hier[t], hier) for t in a.types]
    },
    anyOf(a, hier) :: self.xxxOf("anyOf", a, hier),
    allOf(a, hier) :: self.xxxOf("allOf", a, hier),
    oneOf(a, hier) :: self.xxxOf("oneOf", a, hier),

    // Convert an oschema type to a JSON Schema type
    type(ost, flathier) :: self[ost.schema](ost, flathier),

    // Convert a sequence of oschema types a jsonform flavor of JSON
    // Schema.  The "typeref" gives the type reference in "types" of
    // the type forming the top-level schema.
    convert(types, typeref) :: {
        local hier = moo.oschema.flathier(types),
        local top = hier[typeref],
        schema: $.type(top, hier),
        // form:{}
    },
}

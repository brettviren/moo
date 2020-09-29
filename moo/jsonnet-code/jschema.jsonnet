// support for converting oschema to JSON Schema

local maybe(obj, key, def=null) = if std.objectHas(obj, key) then obj[key] else def;

local select(obj, keys) = {
    [if std.objectHas(obj, k) then k]:obj[k] for k in keys
};

{
    dtypes: {
        i8: { type:"integer", maximum: 2^63-1, minimum: -2^63 },
        i4: { type:"integer", maximum: 2^31-1, minimum: -2^31 },
        i2: { type:"integer", maximum: 2^1-1, minimum: -2^15 },
        u8: { type:"integer", minimum: 0, maximum: 2^64-1 },
        u4: { type:"integer", minimum: 0, maximum: 2^32-1 },
        u2: { type:"integer", minimum: 0, maximum: 2^16-1 },
        f4: { type:"number" },
        f8: { type:"number" },
    },

    boolean(s) :: {type:"boolean"},

    number(s) :: self.dtypes[s.dtype] + maybe(s, "constraints", {}),

    string(s) :: { type: "string" } + select(s, ["format","pattern"]),

    ref(t) :: "#/" + std.join("/", std.split(t, ".")),

    sequence(s) :: { type: "array", items: $.ref(s.items)},

    field(f) :: { "$ref": $.ref(f.item) },

    record(r) :: { type: "object", properties :{
        [f.name]: $.field(f) for f in r.fields
    }},
    
    // Boolean combos
    xxxOf(of, a) :: { [of] : [$.ref(t) for t in a.types] },
    anyOf(a) :: self.xxxOf("anyOf", a),
    allOf(a) :: self.xxxOf("allOf", a),
    oneOf(a) :: self.xxxOf("oneOf", a),

    // Convert an oschema type to a JSON Schema type
    type(ost) :: self[ost.schema](ost),

    // Place and convert oschema type to JSON Schema type
    place(t, p=[]) :: if std.length(p) == 0 then {[t.name]:$.type(t)} else
    {[p[0]]:$.place(t, p[1:])},

    // A sequence of oschema types to a full JSON Schema object.  The
    // "id" argument MUST give an identifier for the resulting JSON
    // Schema.  This is usually in the form of a URL to a JSON file
    // which holds the content of the resulting JSON SChema.
    convert(types, id) :: {
        "$id": id,
        "$schema": "http://json-schema.org/draft-07/schema#",
        definitions: std.foldl(function(p,t) std.mergePatch(p, $.place(t,t.path)),
                               types, {}),
    },
}

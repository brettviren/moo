// A "domain" schema for producing JSON Schema

local re = import "re.jsonnet";
local util = import "util.jsonnet";
local objif = util.objif;

{

    // Refering to a type in JSON Schema is done by name with a
    // special form.  This returns that form.
    ref(type) :: { "$ref": "#/definitions/" + type._tn },

    // Process an array of types and return an object suitable to
    // attach at "#/definitions".
    defs(types) :: { [t._tn]:t._js for t in types },

    // Process an array of types and return a top-level JSON Schema.
    // The "main" object is what the schema exposes and if not given
    // then the last in types will be used.
    top(types, main=null) :: {
        ret : {
            definitions: $.defs(types),
        } + if std.type(main) == "null"
        then types[std.length(types)-1]._js
        else main._js,
    }.ret,
        

    string(name, pattern=null, format=null):: {
        _tn: name,
        _js: { type: "string" } + objif("pattern", pattern) + objif("format", format),
    },


    // Translate best we can to JSON Schema numeric types
    local dtypes = {
        i4: "integer",
        i8: "integer",
        f4: "number",
        f8: "number",
    },

    number(name, dtype, extra={}):: {
        _tn: name,
        _js: {
            type:dtypes[dtype]}
            + {[k]:extra[k] for k in std.objectFields(extra)
               if std.member(["minimum","maximum","exclusiveMinimum","exclusiveMaximum"],k)},
    },

    // Field is fully internal to record so does not use the same _tn/_js pattern.
    field(name, type, default=null, doc=null):: { _name:name, _type:$.ref(type)},
    record(name, fields=[], doc=null) :: {
        _tn: name,
        _js: {
            type: "object",
            properties: {[f._name]: f._type for f in fields},
            required: [f._name for f in fields],
        }+objif("doc",doc),
    },

    enum(name, symbols, default=null, doc=null):: {
        _tn: name,
        _js: {
            type:"string", enum:symbols}+objif("default",default),
    },

    sequence(name, type):: {_tn: name, _js: { type:"array", items:$.ref(type) }},

}

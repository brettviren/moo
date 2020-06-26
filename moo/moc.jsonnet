// this file provides fundamental schema functions for defining moc schema
local moo = import "moo.jsonnet";
local objif(key, val) = if std.type(val)=="null" then {} else {[key]:val};
{
    // The base set of fundamental schema functions simply define the
    // function interfaces, bundle the arguments into the returned
    // object in addition to store the function name as the "what"
    // attribute.
    base: {
        // A true/false Boolean type
        boolean():: {what:"boolean"},

        // A number is specified as a 2 character Numpy dtype (type
        // code + size in byte).
        number(dtype, extra={}):: {what:"number", dtype:dtype},

        // Bytes means a sequence of 8-bit byte values.
        bytes(encoding=null, media_type=null):: {what:"bytes"},

        string(pattern=null, format=null):: {
            what: "string", pattern:pattern, format:format},

        field(name, type, default=null, doc=null):: {
            what:"field", name:name, type:type, default:default, doc:doc
        },

        // A record is a class/struct/object.  
        record(name, fields=[], doc=null) :: {
            what:"record", name:name, fields:fields, doc:doc
        },

        sequence(type) :: {
            what:"sequence", type:type,
        },

        enum(name, symbols, default=null,doc=null):: {
            what:"enum", name:name, symbols:symbols}
            +objif("default",default)+objif("doc",doc),
    },

    // The avro set of fundamental schema functions produce Avro
    // schema objects.
    avro: {
        // A lookup between dtype and avro type
        local dtypes = {               // fixme: need to flesh out
            i4: "int",
            i8: "long",
            f4: "float",
            f8: "double",
        },
        local typeref(what) = if std.type(what)=="string" then what else
            if what.type == "record" then what.name else what,

        // fixme: need function to resolve a type structure to a type
        // name.  For record it is .name which is the type.  All
        // others it is .type

        boolean():: {type:"boolean"},

        // Avro has only four number types and any extra args are ignored.
        number(dtype, extra={}):: {type:dtypes[dtype], dtype:dtype},
        
        // Avro bytes type is fundamental
        bytes(encoding=null, media_type=null):: {type:"bytes"},

        // Avro strings are fundamental.  Pattern and format ignored
        string(pattern=null, format=null):: {type:"string"},

        // A field is an attribute of a record.
        field(name, type, default=null, doc=null):: {
            name:name, type:typeref(type)
        } + objif("default",default) + objif("doc", doc),

        // A record is a class/struct/object.  
        record(name, fields=[], doc=null) :: {
            type: "record", name:name, fields:fields
        } + objif("doc",doc),

        // A sequence in avro is an array
        sequence(type):: { type:"array", items:typeref(type), },

        enum(name, symbols, default=null, doc=null):: {
            type:"enum", name:name, symbols:symbols}+objif("default",default)+objif("doc",doc),
    },
    
    // The jscm set of fundamntal schema functions produce JSON Schema
    // objects for validating JSON objects
    jscm: {
        local dtypes = {               // fixme: need to flesh out
            i4: "integer",
            i8: "integer",
            f4: "number",
            f8: "number",
        },
        
        boolean():: {type: "boolean"},

        // JSON Schema has two number types and range constraints may be given.
        number(dtype, extra={}):: {
            type:dtypes[dtype]}
            + {[k]:extra[k] for k in std.objectFields(extra)
               if std.member(["minimum","maximum","exclusiveMinimum","exclusiveMaximum"],k)},

        // Avro wants us to spell a byte like "\uABCD".  That lets us
        // give bytes directly in some JSON object but is not so good
        // for large binary data.  So we will also accept arbitrary
        // encoding.  Encoded can NOT be directly turned into Avro
        // bytes so some Avro aware interpreter is needed if encoded
        // bytes are to be used.
        bytes(encoding=null, media_type=null):: {
            type: "string",
        } + if std.type(encoding)=="null" then {
            pattern: '^(\\u[a-fA-F0-9]{4})+$',
        } else {
            contentEncoding: encoding} + objif("contentMediaType", media_type),

        // A pattern constrains the string with a regex or format
        // constrains the string to a fixed set formats ("uri",
        // "date", etc).
        string(pattern=null, format=null):: {
            type: "string" } + objif("pattern", pattern) + objif("format", format),


        // 
        field(name, type, default=null, doc=null):: {
            what:"field", name:name, type:type}+objif("default",default)+objif("doc",doc),

        // A record matches a JSON object wth some set of fields.
        // Name is ignored
        record(name, fields=[], doc=null) :: {
            type: "object",
            properties: {[f.name]: {type: f.type} for f in fields},
            required: [f.name for f in fields],
        }+objif("doc",doc),

        // A sequence in JSON Schema is an array
        sequence(type):: { type:"array", items:type, },
        
        // Like record, enum does not have a name
        enum(name, symbols, default=null, doc=null):: {
            type:"string", enum:symbols}+objif("default",default)+objif("doc",doc),
    }
}

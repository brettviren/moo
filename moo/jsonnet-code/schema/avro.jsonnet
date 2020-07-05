local re = import "re.jsonnet";
local util = import "util.jsonnet";
local objif = util.objif;

// A "domain" schema for producing Avro Schema.
//
// Schema in domain is handled with two keywords
//
// - _tn: a "type name" to refer to the type
// - _as: the avro schema object defining the type
//
// Some types (string, number and sequence) are "inline" in avro and
// can not be refered to indirectly.  These lack any "_as" key as
// there is never an ability to give Avro any stand-alone schema and
// instead "_tn" holds the schema object.
//
// Warning, Avro requires schema elements to be ordered by dependency.
// Most independent must come first.  This must be honored at the
// application schema level.
//
{
    // A lookup between dtype and avro type
    local dtypes = {               // fixme: need to flesh out
        i4: "int",
        i8: "long",
        f4: "float",
        f8: "double",
    },

    // Return a string representation of the type (aka of the schema object)
    ref(type) :: type._tn,

    // Export the internal Jsonnet representation of application
    // defined types to native Avro schema.
    export(types) :: [t._as for t in types if std.objectHas(t,'_as')],

    // Build an Avro schema from an application schema. 
    build(app_schema) :: self.export(app_schema(self).types),

    // In Avro domain, all string types are degenerate.
    string(name=null, pattern=null, format=null):: {
        _tn: "string",
    },

    // Avro has only four number types and any extra args are ignored.
    number(name=null, dtype, extra={}):: {
        _tn: dtypes[dtype],
    },

    // Avro sequence is always inline, never referenced.
    sequence(name, type):: {
        _tn: { type:"array", items:$.ref(type) },
    },

    // A field is not a first class type but is used only by record.
    // This function produces Avro Schema directly
    field(name, type, default=null, doc=null):: {
        name:name, type:$.ref(type)
    } + objif("default",default) + objif("doc", doc),

    record(name, fields=[], doc=null) :: {
        _tn: name,
        _as: { type: "record", name:name, fields:fields } + objif("doc",doc),
    },

    enum(name, symbols, default=null, doc=null):: {
        _tn: name,
        _as: { type:"enum",
               name:name,
               symbols:symbols }+objif("default",default)+objif("doc",doc)},
}


// Define a JSON Schema that validates Avro schema documents
// https://avro.apache.org/docs/current/spec.html
local moo = import "moo.jsonnet";
local ms = moo.schema;

local primitives = {
    integers: ["int", "long"],
    floats: ["float", "double"],
    numbers: self.integers + self.floats,
    strings: ["bytes", "string"],
    not_null: self.numbers + self.strings + ["boolean"],
    all: self.not_null + ["null"],
};

local tn(n, extra={}) = {type:n} + extra;

{
    schema: {
        definitions: {

            // Avro "names" and enum "symbols" may not be any string but
            // must match the regex [A-Za-z_][A-Za-z0-9_]*.  For now, just
            // allow any string.
            name: ms.string(pattern='^[A-Za-z_][A-Za-z0-9_]*$'),
            namespace: ms.string(pattern='^([A-Za-z_][A-Za-z0-9_]*)(\\.[A-Za-z_][A-Za-z0-9_]*)*$'),

            // Type names are first class in Avro schema but there's no
            // way to represent them explicitly destinct from all possible
            // strings.
            type_name: ms.string(),

            primitive_type_name: ms.enum(primitives.all),

            primitive_type: ms.oneOf([
                ms.object({type:ms.const(name)},["type"])
                for name in primitives.all]),

            field: ms.object({
                name: ms.def("name"),
                doc: ms.string(),
                type: ms.def("schema"),
                default: true,      // really only should match base on type
                order: ms.enum(["ascending", "descending", "ignore"]),
                aliases: ms.array(ms.def("type_name")),
            }, ["type", "name"]),

            record: ms.object({
                type: ms.const("record"),
                name: ms.def("name"),
                namespace: ms.def("namespace"),
                doc: ms.string(),
                aliases: ms.array(ms.string()),
                fields: ms.array(ms.def("field")),
            },["type", "name", "fields"]),

            enum: ms.object({
                type: ms.const("enum"),
                name: ms.def("name"),
                namespace: ms.def("namespace"),
                doc: ms.string(),
                aliases: ms.array(ms.string()),
                symbols: ms.array(ms.string()),
                default: ms.string(),
            }, ["type", "name", "symbols"]),

            array: ms.object({
                type: ms.const("array"),
                items: ms.def("schema"),            
            }, ["type", "items"]),

            map: ms.object({
                type: ms.const("map"),
                values: ms.def("schema"),
            }, ["type", "values"]),
            
            union: ms.array(ms.anyOf(self.all_but_union)),
            
            fixed: ms.object({
                type: ms.const("fixed"),
                name: ms.def("name"),
                namespace: ms.def("namespace"),
                aliases: ms.array(ms.string()),
                size: ms.integer(),
            },["type", "name", "size"]),

            all_but_union:: [
                ms.def("map"),
                ms.def("array"),
                ms.def("enum"),
                ms.def("record"),
                ms.def("primitive_type"),
                ms.def("primitive_type_name"),
                ms.def("type_name"),
            ],

            all:: self.all_but_union + [self.union],
            schema: ms.anyOf(self.all),
        },
        anyOf: self.definitions.all
    },

    /// Functions to create models which are valid against Avro schema
    model: {
        // first make the primitives into attributes to avoid
        // stringification of type names in user models.
        nulltype:tn("null"),
    } + {[n]:tn(n) for n in primitives.not_null } + {

        // Define a field of a record
        field(name, type, default=null, order="ignore", aliases=[], doc=""):: {
            type:type, name:name, default:default, order:order,
            aliases:aliases, doc:doc
        },

        // Define a record
        record(name, fields, namespace="", aliases=[], doc="") :: {
            type:"record",
            name:name, fields:fields, namespace:namespace,
            aliases:aliases, doc:doc
        },

        // Define an enum
        enum(name, symbols, namespace="", aliases="", default="", doc=""):: {
            type:"enum",
            name:name, symbols:symbols, namespace:namespace,
            aliases:aliases, default:default, doc:doc
        },

        // Define an array
        array(items) :: { type:"array", items:items },

        // Define a map
        map(vtype) :: {type:"map", values: vtype },

        // Define a union.  This is just its arguments
        union(types) :: types,

        // Define a fixed
        fixed(name, size, namespace="", aliases=[]) :: {
            type:"fixed", name:name, size:size,
            namespace:namespace, aliases:aliases
        },

    }
}

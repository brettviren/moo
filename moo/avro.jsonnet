// Define a JSON Schema that validates Avro schema documents
// https://avro.apache.org/docs/current/spec.html

// fixme: would like a way to generate a JSON Schema from Avro Schema
// so that an Avro object may be validated.

local moo = import "moo.jsonnet";
local ms = moo.schema;
local objif(key, val) = if std.type(val)=="null" then {} else {[key]:val};
local primitives = {
    integers: ["int", "long"],
    floats: ["float", "double"],
    numbers: self.integers + self.floats,
    strings: ["bytes", "string"],
    not_null: self.numbers + self.strings + ["boolean"],
    all: self.not_null + ["null"],
};

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
                ms.def("type_name"),
                ms.def("primitive_type_name"),
                ms.def("primitive_type"),
                ms.def("enum"),
                ms.def("record"),
                ms.def("map"),
                ms.def("array"),
            ],

            all:: self.all_but_union + [self.union],
            schema: ms.anyOf(self.all),
        },
        anyOf: self.definitions.all
    },

    /// Functions to create models which are valid against JSON Schema for Avro schema.
    ///
    model: {
        // first make the primitives into attributes to avoid
        // stringification of type names in user models.
        nulltype:"null",
    } + {[n]:n for n in primitives.not_null } + {

        // Define a field of a record
        field(name, type, default=null, order="ignore", aliases=null, doc=null):: {
            type:type, name:name, order:order,
        } +objif("default", default) +objif("aliases",aliases)+objif("doc",doc),

        // Define a record
        record(name, fields, namespace=null, aliases=null, doc=null) :: {
            type:"record",
            name:name, fields:fields
        } + objif("namespace", namespace) + objif("aliases", aliases) + objif("doc", doc),

        // Define an enum
        enum(name, symbols, namespace=null, aliases=null, default=null, doc=null):: {
            type:"enum", name:name, symbols:symbols, 
        } + objif("namespace", namespace) + objif("aliases", aliases)
            + objif("default", default) + objif("doc", doc),

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

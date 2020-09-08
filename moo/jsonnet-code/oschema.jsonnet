// Construct schema in specific object representation.
//
// The "meta schema" of the schema is an amalgamation of avro and json
// schema.
//
// Each type object is itself "anonymous" (lacking any internal name).
// It is expected that related types will be provided in values of an
// object where the keys provide a local, short name.  A hiearchy of
// such objects may be formed in order to represent namespaces.
// Functions are provided to operate on such object to: encode a local
// .name and .fqn (fully qualified name), flatten the hiearchy, and
// apply a topological sort.

local _tsmod = import "toposort.jsonnet";

local is(x) = std.type(x) != "null";
local isr(x,r) = if std.type(x) != "null" then r;

{
    /// Form a fully qualified type name
    fqn(type) :: std.join(".", type.path + [type.name]),

    schema(ctx=[])  :: {
        local namepath = if std.type(ctx) == "string" then std.split(ctx,'.') else ctx,
        // Common attributes for every type.
        type(name, schema, doc=null, deps=[]) :: {
            name: name,           // local short name for the type
            path: namepath,       // the context path (ie, namespace)
            schema: schema,       // The "schema class"
            deps: deps, // Hold fqn type name of dependencies
            [isr(doc,"doc")]:doc, // optional docstring
        },

        boolean(name, doc=null) :: self.type(name, "boolean", doc),

        string(name, pattern=null, format=null, doc=null)
        :: self.type(name, "string", doc) {
            [if is(pattern) then "pattern"]: pattern,
            [if is(format) then "format"]: format,
        },

        number(name, dtype, constraints=null, doc=null)
        :: self.type(name, "number", doc) {
            dtype: dtype,
            [if is(constraints) then "constraints"]: constraints,
        },

        // A sequence, vector, array with items all of one type.
        sequence(name, items, doc=null)
        :: self.type(name, "sequence", doc, [$.fqn(items)]) {
            items: self.deps[0],
        },
        
        // We do not consider a field as a type but rather a named holder
        // of a type and an optional default value.  The value should be a
        // literal representation.  Eg, if the type is string like the
        // default value should be like '"foo"'.  A number may be
        // specified like '6.9' or may be a JSON 6.9 but the latter may
        // suffer representation round-off.  Fields of type record are
        // allowed but any defaults will be very specific to the codegen
        // target language and thus may lead to the schema not being
        // generic.  Eg, '{1,"foo",6.9}' may be a valid initialization
        // list for codgen targetting a C++ struct but will utterly fail
        // if applied to generating a Python class.  
        field(name, type, default=null, doc=null) :: {
            name: name,
            item: $.fqn(type),
            [isr(default,"default")] : default,
        },

        record(name, fields=[], bases=null, doc=null)
        :: self.type(name, "record", doc, [f.item for f in fields]) {
            fields: fields,
            [if is(bases) then "bases"]: bases,            
        },

        enum(name, symbols, default=null, doc=null)
        :: self.type(name, "enum", doc) {
            [if is(default) then "default"]: default,
            symbols: symbols,
        },

        // This may translate into, eg boost::any or nlohmann::json
        any(name, doc=null) :: self.type(name, "any", doc) { },

        // This may tranlate into, eg std::variant
        anyOf(name, types, doc=null) :: self.type(name, "anyOf", doc, types) {
            types: types,
        },
    },
    // Utility functions

    // Take an object with values that are types and return one with
    // the keys produced from fully qualifying type context and name.
    qualify(obj) :: {
        [self.fqn(obj[k])]:obj[k]
        for k in std.objectFields(obj)
    },
    
    // Return types used by the type as list of fqns
    deps(type) :: type.deps,

    // Sort the keys of a qualified object 
    sort :: _tsmod(edges = function(graph, n) self.deps(graph[n])).toposort,

}

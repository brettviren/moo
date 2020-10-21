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
    // Return the leading part of a dotpath p with the leaf removed
    basepath(p) :: {
        local np = $.listify(p),
        res: std.join(".",np[:std.length(np)-1])
    }.res,

    // Return trailing part of path p with path b removed
    relpath(p, b) :: {
        local np = $.listify(p),
        local bp = $.listify(b),
        // note, "in" is kind of reversed here.  bp must be a prefix of np
        assert $.isin(bp, np),
        res: std.join(".",np[std.length(bp):])
    }.res,

    // If path array p is not empty join it with delim and add a delim at end
    prepath(p, delim=".") :: 
    if std.length(p) == 0 then "" else std.join(delim, p) + delim,



    /// Form a fully qualified type name
    fqn(type) :: std.join(".", type.path + [type.name]),

    listify(o) :: if std.type(o) == "null" then [] else
        if std.type(o) == "string" then std.split(o, '.') else o,

    // Place type t into path p
    place(t, p=[]) :: if std.length(p) == 0 then {[t.name]:t} else
    {[p[0]]:$.place(t, p[1:])},

    // Place types into their path/name hierachy
    hier(types) :: std.foldl(function(p,t) std.mergePatch(p,$.place(t,t.path)), types, {}),

    class_names: ["boolean", "string", "number", "sequence",
                  "record", "enum", "any", "anyOf", "namespace"],

    schema(ctx=[]) :: {
        local namepath = $.listify(ctx),
        // Set common attributes for every type, call as self.type(...)
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
            [isr(pattern,"pattern")]: pattern,
            [isr(format,"format")]: format,
        },

        number(name, dtype, constraints=null, doc=null)
        :: self.type(name, "number", doc) {
            dtype: dtype,
            [isr(constraints,"constraints")]: constraints,
        },

        // A sequence, vector, array with items all of one type.
        sequence(name, items, doc=null)
        :: self.type(name, "sequence", doc, [$.fqn(items)]) {
            items: self.deps[0],
        },
        
        // A field provides an attribute for a record.  We do not
        // consider a field itself as a type but rather a holder of a
        // name, a type an (optional) default value and an optional
        // marker.  Some rules for fields:
        //
        // - the "default" should be provided as literal JSON data
        // which is consistent with the schema for the type of the
        // field.  Eg, a string is "hi", a number is 42, a field which
        // is itself a record is a JSON object.
        //
        // - if "optional" is set to true then targets may accept a
        // record lacking this field.  By default, a field is
        // required.
        field(name, type, default=null, optional=null, doc=null) :: {
            local defres = if std.type(default) == "null" && std.objectHas(type,"default") then type.default else default,
            res: {
                name: name,
                item: $.fqn(type),
                [isr(optional,"optional")]: optional,
                [isr(defres,"default")] : defres,
                [isr(doc,"doc")]: doc,
            }
        }.res,

        // A record is a collection of fields.  It may have a zero or
        // more "base" records.
        record(name, fields=[], bases=null, doc=null)
        :: self.type(name, "record", doc, [f.item for f in fields]) {
            fields: fields,
            [isr(bases, "bases")]: bases,            
        },

        // Make an enumerated list type.  A default must be in the
        // list of symbols.  If omitted, the first in the list is default.
        enum(name, symbols, default=null, doc=null)
        :: self.type(name, "enum", doc) {
            local defres = if std.type(default) == "null" then symbols[0] else default,
            assert std.length(std.find(defres, symbols)) > 0,
            default: defres,
            symbols: symbols,
        },

        // This may translate into, eg boost::any or nlohmann::json
        any(name, doc=null) :: self.type(name, "any", doc),

        // parameterize across {any,all,one}Of
        xxxOf(sname, name, types, doc=null)
        :: self.type(name, sname, doc, [$.fqn(t) for t in types]) {
            types: self.deps,
        },
        // anyOf type lets any of the listed type be acceptable.  This
        // is mostly for validation but could be mapped to code as a
        // simple union type with some hope / external mechanism to
        // restrict which of the subset of types may actually be accessed.
        anyOf(name, types, doc=null) :: self.xxxOf("anyOf", name, types, doc),
        // allOf type requires that every type is consistent.  This is
        // mostly used for validation but could be mapped as a simple
        // union type.
        allOf(name, types, doc=null) :: self.xxxOf("allOf", name, types, doc),
        // oneOf type requires that exactly one type is acceptable.
        // This is mostly used for validatino but could be mapped to
        // code as a tagged union type (eg std::variant<>).
        oneOf(name, types, doc=null) :: self.xxxOf("oneOf", name, types, doc),

        // subnamespace(name, types, subpath=null, doc=null) :: {
        //     local fullpath = namepath + $.listify(subpath),
        //     local mytypes = [t for t in types if $.isin(fullpath, t.path)],
        //     local hier = {[t.name]:t for t in mytypes},
        //     res : {
        //         name: name, [isr(doc,"doc")]:doc,
        //         path: fullpath,
        //         deps: [$.fqn(t) for t in mytypes],
        //     } + hier,
        // }.res,
    },
    // Utility functions

    namespace(name, types, path=null, doc=null) :: {
        local fullpath = $.listify(path),
        local mpath = fullpath + if name == "" then [] else [name],
        local mytypes = [t for t in types if $.isin(mpath, t.path)],
        local hier = {[t.name]:t for t in mytypes},
        res : {
            schema: "namespace",
            name: name, [isr(doc,"doc")]:doc,
            path: fullpath,
            deps: [$.fqn(t) for t in mytypes],
        } + hier,
    }.res,

    // Return topologically sorted and selected array of types in path.
    sort_select(oot, path=[]):: {
        local mpath = $.listify(path),
        local graph = $.qualify(oot),
        //res: [std.mergePatch(graph[k],{deps:null}) for k in $.sort(graph) if $.isin(mpath, graph[k].path)],
        res: [graph[k] for k in $.sort(graph) if $.isin(mpath, graph[k].path)],        
    }.res,        

    // Return True if b is in (or under) a
    isin(a, b) :: if std.length(a) == 0 then true else if std.length(b) == 0 then false else if b[0] != a[0] then false else $.isin(a[1:], b[1:]),

    // Take an object with values that are types and return one with
    // the keys produced from fully qualifying type context and name.
    qualify(oot) :: if std.type(oot) == "array" then {
        [$.fqn(t)]:t for t in oot
    } else {
        [$.fqn(oot[k])]:oot[k] for k in std.objectFields(oot)
    },
    
    // Return edges to other nodes reached from n in graph.
    edges(graph, n) :: [d for d in graph[n].deps if std.objectHas(graph, d)],

    // Sort the keys of a qualified object 
    sort :: _tsmod(edges = $.edges).toposort,

}

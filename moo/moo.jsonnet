local jss = import "jss.json";

local json_schema_version = "draft-07";
local objif(key, val) = if std.type(val)=="null" then {} else {[key]:val};

{
    // Create an object that, in an array, may be rendered with the
    // command "moo render-many".
    render(model, template, filename) :: {
        model:model, template:template, filename:filename,
    },

    zmq : {
        socket : {
            // these are in intentional order
            names : ["pair","pub","sub","req","rep","dealer","router",
                     "pull","push","xpub","xsub","stream",
                     "server","client","radio","dish",
                     "gather","scatter","dgram"],
            type: {[$.zmq.socket.names[n]]:n
                   for n in std.range(0,std.length($.zmq.socket.names)-1)},
            linkage: ["bind","connect"],
        },
    },

    // Collect supported unit identifiers.
    units : {
        time: ["s","ms","us","ns","tick"],
        data: ["kB", "MB", "GB", "TB"],
        data_rate: ["kbps", "Mbps", "Gbps", "Tbps"],
        all: self.time + self.data + self.data_rate,
    },
    
    // Numeric types follow Numpy codes and two characters giving
    // representation format and size in bytes.  Eg, i2 is a two
    // byte,, signed integer.
    //
    // - b :: byte (signed)
    // - B :: byte (unsigned)
    // - i :: integer (signed)
    // - u :: integer (unsigned)
    // - f :: floating point
    // - c :: complext floating point
    dtypes: {
        sint: ["i2", "i4", "i8"],
        uint: ["u2", "u4", "u8"],
        aint: self.sint + self.uint, // all ints
        float: ["f2", "f4", "f8"],
        complex: ["c2", "c4", "c8"],
        bytes: ["b1", "B1"],
        all: self.aint + self.float + self.complex + self.bytes,
    },
    

    // This structure reflects JSON Schema vocabulary into Jsonnet and
    // extends it to define JSON Schema for moo vocabulary.  JSON
    // Schema describes what types of structure is allowed in a model.
    // moo scheme extends JSON Schema to define a more narrow allowed
    // structure and to give it stronger semantic meaning.
    schema : {

        // Produce a JSON Schema for an object.
        object(properties, required=[]) :: {
            // Mark as JSON Schema object type 
            type:"object",
            // The allowed attributes are defined through a properties
            // object.
            properties:properties,
            // A list of required property keywords
            required:required,
            // tbd. JSON Schema supports a few more things
        },

        // Return object with obj2 merged into obj1
        update(obj1, obj2) :: obj1 + {
            properties: obj1.properties + obj2.properties,
            required: obj1.required + obj2.required
        },

        /// A JSON Schema null type matches literal null
        nulltype() :: {type:"null"},

        /// A JSON Schema boolean matches literal true or false
        boolean() :: {type:"string"},

        /// A JSON Schema string schema matches any literal string in
        /// a model.
        string(format=null,pattern=null) :: {
            type:"string"} + objif("format", format)
            + objif("pattern", pattern),

        /// A JSON Schema number matches any literal number in a
        /// model.
        number(dtype=null) :: { type:"number" } + objif("dtype", dtype),

        /// Narrow to matching just literal integers
        integer(dtype="i4") :: { type:"integer", dtype:dtype },

        /// A litteral array of items in a model.  Items may be a
        /// single schema object or an array of schema objects.
        array(items=[],minItems=0) ::
        {type:"array", items:items, minItems:minItems},

        /// Matches a specific, literal string in the model.
        const(str) :: { const: str },

        /// Match any of a set of specific, literal strings
        enum(lst=[]) :: { type:"string", enum:lst},

        /// A model must be valid against all schema in lst.
        allOf(lst) :: {allOf: lst},

        /// A model must be valid against at least one schema in lst.
        anyOf(lst) :: {anyOf: lst},

        /// A model must be valid against exactly one schema in lst.
        oneOf(lst) :: {oneOf: lst},

        /// JSON Schema allows chunks of schema to be referenced and
        /// logically inserted by this special form.  The path may be
        /// a URL or a special local path into the document.  See def()
        ref(path) :: {"$ref": path },

        /// JSON Schema "draft-08" convention places reusable schema
        /// under this special path in the JSON structure in order to
        /// then reference it.
        def(id) :: {"$ref": "#/definitions/"+id },

        /// Top level schema is one with some extras attributes.  The
        /// "id" should point to a URL controlled by the developer of
        /// the schema which holds some definition of the schema.
        schema(id, body={}, definitions={}, version=json_schema_version) ::
        {"$schema": "http://json-schema.org/%s/schema#"%version,
         "$id": id, definitions:definitions} + body,

        // A JSON Schema document may itself be validated against this
        // schema which is written as a JSON Schema document:
        metaschema(version=json_schema_version) :: {
            "$ref":  "https://json-schema.org/%s/schema"%version },
    },


    mootypes: {
        /// moo defines JSON Schema structure based on a
        /// "sub-vocabulary" that resides in JSON Schema "object".
        
        /// The mooscheme() function returns a JSON Schema data
        /// structure that validates a more narrow type.
        mooscheme(mt, properties, required=[]) ::
        self.object(properties + {
            // Every moo model has a type and this literal string names it
            mootype:mt,
            // Every model must have a description of JSON Schema type string.
            description: $.schema.string(),
        }, required+["mootype","description"]),

        /// moo accepts models of numeric type that satisfy the
        /// numeric scheme.  moo adopts Numpy dtype identifiers and
        /// allows for an optional unit.  A moo num is a distinct type
        /// from a JSON Schema "number".  The latter describes a
        /// literal number given in a model.
        num(dtypes=$.dtypes.numeric, units=$.units.all) ::
        self.mooscheme("num", {
            // a moo num type must provide a specific dtype
            dtype: $.schema.enum(dtypes),
            // a moo num type must provide a default value
            def: $.schema.number(),
            // a moo num type may provide a unit
            unit: $.schema.oneOf(units)}, ["dtype"]),
        
        /// moo accepts models of string types.  Note, a moo string
        /// type is different than a JSON Schema string type.  The
        /// latter is a schema describing a litteral string in the
        /// model (eg, a mootype attribute).  A default value,
        /// (expressed as a JSON Schema string type) is required.
        str() :: self.mooscheme("str", {
            def: $.schema.string(),
        }, ["def"]),

        /// moo accepts models of type timestamp.  A timestamp is a
        /// numeric with a narrowed integer type and units.
        timestamp(dtypes=["i4","i8"], units=$.units.time) ::
        self.mooscheme("timestamp", {
            // a moo timestamp must provide an integer type
            dtype: $.schema.enum(dtypes),
            // a moo timestamp type must provide a default int value
            def: $.schema.integer(),
            // a moo time stamp may provide a time unit
            unit: $.schema.enum(units),
        }, ["dtype"])
    },
    
    /// moo.types functions return a model data structure which may be
    /// validated by some moo schema.
    types : {

        /// A base function to construct a scheme-valid description of
        /// a moo type.
        mootype(mt, desc, rest) :: {mootype:mt, description:desc} + rest,

        /// A moo numeric type has a specific Numpy data type (dtype)
        /// and optional unit.
        num(dtype, desc, unit=null, def=0) ::
        self.mootype("num", desc, {dtype:dtype, def:def} + objif("unit", unit)),


        /// A C-style int type is taken as 4 byte, signed, no unit
        int(desc) :: self.num('i4', desc),

        /// A moo string type 
        str(desc, def="") :: self.mootype("str", desc, {def:def}),

        /// Time stamps
        timestamp(dtype="i8", unit="s") :: self.timestamp(dtype, unit),
        
    },

    /// support for templates
    templ : {
        lang : {                // plain data map fom mootype to lang type
            cpp : {
                str: {
                    "<U": "std::string",
                    "S": "std::byte",
                },
                num: {
                    i8: "int64_t",
                    i4: "int32_t",
                }
            }
        }
    }

}

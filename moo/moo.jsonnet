local jss = import "jss.json";

{

    data : {
        units : {
            time: ["s","ms","us","ns","tick"],
        },
        
        dtypes: {
            sint: ["i2", "i4", "i8"],
            uint: ["u2", "u4", "u8"],
        }
    },


    schema : {

        // Produce a JSON Schema for an object
        object(properties, required=[]) :: {
            type:"object",
            properties:properties,
            required:required},

        string(format=null) :: {type:"string", format:format},

        number() :: { type:"number"},

        integer() :: { type:"integer" },

        array(items=null) ::
        {type:"array", items:items},

        const(str) :: { const: str },
        enum(lst=[]) :: { type:"string", enum:lst},

        allOf(lst) :: {allOf: lst},
        anyOf(lst) :: {anyOf: lst},
        oneOf(lst) :: {oneOf: lst},

        def(id) :: {"$ref": "#/definitions/"+id },
        ref(path) :: {"$ref": path },

        schema(body={}, definitions={}, version="draft-07") ::
        {"$schema": "http://json-schema.org/%s/schema#"%version,
         definitions:definitions} + body,

        // In our models we may express schema and we do so using JSON
        // Schema.  This schema is that of JSON Schema itself.
        jsonschema() :: { "$ref":  "https://json-schema.org/draft-07/schema" },

        /// Now we give some additional schema in the form of objects.
        /// By default these leave ambiguity and are not convenient to
        /// us in a model (because then the template has to handle
        /// things like allOf).  Models that need to express schema
        /// directives in an unambiguous manner should use what is
        /// under .types.

        /// Every moo schema extension object requires a mootype.
        mootype(mt, properties, required=[]) ::
        self.object(properties + {mootype:mt}, required+["mootype"]),

        /// For a model to be used to describe something of numeric
        /// type in code we often must be more specific than just
        /// "number".  Here we must give one or more "dtypes" that a
        /// model may provide.  moo takes "dtype" as any code
        /// understood by Numpy.  An optional units may also be
        /// provided to help templates.  Units should be as foundin
        /// $.data.units
        num(dtypes=$.data.dtypes.numeric, units=$.data.units.all) ::
        self.mootype("num", {
            dtype: $.schema.enum(dtypes),
            unit: units}, ["dtype"]),
        
        timestamp(dtypes=["i4","i8"], units=$.data.units.time) ::
        self.mootype("num", {
            dtype: $.schema.enum(dtypes),
            unit: $.schema.enum(units),
        }, ["dtype"])
    },
    
    /// moo.types correspond to the same named functions in moo.schema
    /// but are assertive and unambiguous.  
    types : {

        mootype(mt, dtype, obj) :: {mootype:mt, dtype:dtype} + obj,

        /// A moo string may take a default
        str(def="") :: self.mootype("str", "<U", {def:def}),

        /// Model a numeric of a specific data type and optional unit.
        num(dtype, unit=null, def=0) ::
        self.mootype("num", dtype, {def:def, unit:unit}),

        /// An integer type is taken as 4 byte, signed, no unit
        int() :: self.num('i4'),

        /// Time stamps
        timestamp(dtype="i8", unit="s") :: self.num(dtype, unit)
        
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

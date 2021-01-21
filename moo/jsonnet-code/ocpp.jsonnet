// This holds some translation from Jsonnet schema to C++ syntax
// templates.  This file provides reasonable defaults but some
// projects may desire to interpret schema differently (eg a different
// "Any" type or different allowed dtypes).

// Suggested use is to "graft" it into a model so it is available
// model.lang.*:
//
//   moo -g '/lang:ocpp.jsonnet' [...] some-cplusplus-template.hpp.j2
{
    types: {            // type conversion between schema and C++
        string: "std::string",
        any: "nlohmann::json",
        sequence: "std::vector",
        boolean: "bool",
    },
    // fixme: there are more numpy dtypes that are supported here!
    dtypes: {
        i2: "int16_t",
        i4: "int32_t",
        i8: "int64_t",
        u2: "uint16_t",
        u4: "uint32_t",
        u8: "uint64_t",
        f4: "float",
        f8: "double",
    },
    imports: {          // ie, the ... in #include <...>
        sequence: ["vector"],
        string: ["string"],
        enum: ["string"],
        anyof: ["variant"],
        any: ["nlohmann/json.hpp"],
    }
}

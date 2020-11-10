// some C++ specific helpers for templates.
// Suggested use:
//   moo -g '/lang:ocpp.jsonnet' [...]
{
    types: {            // type conversion between schema and C++
        string: "std::string",
        any: "nlohmann::json",
        sequence: "std::vector"
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
        anyof: ["variant"],
        any: ["nlohmann/json.hpp"],
    }
}

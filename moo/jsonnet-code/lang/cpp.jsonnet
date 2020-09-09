// moo support for C++ language templates.
// FIXME: this must follow the same structure as other eg, one for Python.
{
    types: {            // type conversion between schema and C++
        string: "std::string",
        any: "nlohman::json",
        sequence: "std::vector"
    },
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
        string: ["string"],
        anyof: ["variant"],
        any: ["nlohman/json.hpp"],
    }
}

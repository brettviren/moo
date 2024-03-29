// This holds some translation from Jsonnet schema to python syntax
// templates.  This file provides reasonable defaults but some
// projects may desire to interpret schema differently (eg a different
// "Any" type or different allowed dtypes).

// Suggested use is to "graft" it into a model so it is available
// model.lang.*:
//
//   moo -g '/lang:opython.jsonnet' [...] some-python-template.py.j2
{
    types: {            // type conversion between schema and python
        string: "str",
        any: "dict",
        sequence: "list",
        boolean: "bool",
    },
    // fixme: there are more numpy dtypes that are supported here!
    dtypes: {
        i2: "np.int16",
        i4: "np.int32",
        i8: "np.int64",
        u2: "np.uint16",
        u4: "np.uint32",
        u8: "np.uint64",
        f4: "np.float32",
        f8: "np.float64",
    },
    // imports: {          // ie, the ... in #include <...>
    //     sequence: ["list"],
    //     string: ["string"],
    //     enum: ["string"],
    //     anyOf: ["variant"],
    //     oneOf: ["variant"],
    //     any: ["nlohmann/json.hpp"],
    // }
}

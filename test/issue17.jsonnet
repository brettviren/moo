local moo = import "moo.jsonnet";
local as = moo.oschema.schema("test.issue17");
local nc = moo.oschema.numeric_constraints;

local hier = {
    float: as.number("FloatPos", dtype='f4',
                     constraints=nc(minimum=0.0, exclusiveMaximum=1.0)),
    double: as.number("DoublePos", dtype='f8',
                      constraints=nc(exclusiveMinimum=0.0, maximum=1e34)),
    natural: as.number("Natural", dtype='i4',
                       constraints=nc(multipleOf=1.0, minimum=0.0)),
    even: as.number("Even", dtype='i8',
                    constraints=nc(multipleOf=2.0))
};

{
    hier: hier,
    pass: {
        schema: ["float","float","double","float","double",
                 "natural","natural","natural",
                 "even","even","even","even"],
        models: [
            0.0, 0.999999, 1152921504606846976, 0.8, 0.8,
            0.0, 1.0, 34,
            0.0, 0, 2, -2],
    },
    fail: {
        schema: ["float", "float", "float", "double", "double",
                 "natural", "natural",
                 "even", "even", "even", "even"],
        models: [-0.00001, 1.0, 1.0, 0.0, 1e35,
                 -1, 2.2,
                 1.0, 1, 2.3, -2.7],
    },
}

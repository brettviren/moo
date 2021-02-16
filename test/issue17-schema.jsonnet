local moo = import "moo.jsonnet";
local as = moo.oschema.schema("test.issue17");
local nc = moo.oschema.numeric_constraints;

// Very contrived:
[
    as.number("FloatPos", dtype='f4',
              constraints=nc(minimum=0.0, exclusiveMaximum=1.0)),
    as.number("DoublePos", dtype='f8',
              constraints=nc(exclusiveMinimum=0.0, maximum=1e34)),
    as.number("Natural", dtype='i4',
              constraints=nc(multipleOf=1.0, minimum=0.0)),
    as.number("Even", dtype='i8',
              constraints=nc(multipleOf=2.0)),
]

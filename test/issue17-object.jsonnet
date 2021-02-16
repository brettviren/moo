// an object to test against issue17-schema.jsonnet
local s = import "issue17-schema.jsonnet";
local t = import "testing.jsonnet";
local v = t.validate(s);
local st = v.unit;
local ms = v.mschema;

// these should pass
local pass = [
    st(ms.FloatPos, 0.0),
    st(ms.FloatPos, 0.999999),
    st(ms.DoublePos, 1152921504606846976), // Rachel number
    st(ms.FloatPos, 0.8),
    st(ms.DoublePos, 0.8),        

    st(ms.Natural, 0.0),
    st(ms.Natural, 1.0),
    st(ms.Natural, 34),

    st(ms.Even, 0.0),
    st(ms.Even, 0),
    st(ms.Even, 2),
    st(ms.Even, -2),
];

// these should fail
local fail = [
    st(ms.FloatPos, -0.00001),
    st(ms.FloatPos, 1.0),
    st(ms.FloatPos, 1.0),
    st(ms.DoublePos, 0.0),
    st(ms.DoublePos, 1e35),

    st(ms.Natural, -1),
    st(ms.Natural, 2.2),

    st(ms.Even, 1.0),
    st(ms.Even, 1),
    st(ms.Even, 2.3),
    st(ms.Even, -2.7),

];

{
    pass: v.transpose_units(pass),
    fail: v.transpose_units(fail),
}

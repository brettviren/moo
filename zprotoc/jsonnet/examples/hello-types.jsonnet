local moo = import "moo.jsonnet";
local lang = import "moo/cpp.jsonnet";
{
    types: lang.types,
    namespace: "hello",
    obj: moo.object("MyType",[
        moo.attribute("x",lang.types.integer,0),
        moo.attribute("s",lang.types.string,'""')]),
}


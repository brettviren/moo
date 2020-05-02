local moo = import "moo.jsonnet";
{
    namespace: "hello",
    obj: moo.object("MyType",[
        moo.attribute("x",moo.types.int),
        moo.attribute("s",moo.types.str)]),
}


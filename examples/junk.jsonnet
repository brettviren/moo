local moo_maker = import "moo.jsonnet";
local moo = moo_maker(import "moo/cpp.jsonnet");

{
    a: moo.object("foo"),
    b: moo.lang.types,
}

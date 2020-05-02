local moo = import "moo.jsonnet";
[
    moo.attribute("color", moo.types.str, "purple"),
    moo.attribute("count", moo.types.int, 0),
]

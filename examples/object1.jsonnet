local moo = import "moo.jsonnet";

moo.object("candies", [
    moo.attribute("color", moo.types.str, "purple"),
    moo.attribute("count", moo.types.int, 0),
], "A container full of yumminess")

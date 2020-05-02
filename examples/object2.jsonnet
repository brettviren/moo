local moo = import "moo.jsonnet";
local candies = moo.object("candies", [
    moo.attribute("color", moo.types.str, "purple"),
    moo.attribute("count", moo.types.int, 0),
]);
moo.object("eat", [
    moo.attribute("snack", candies),
])

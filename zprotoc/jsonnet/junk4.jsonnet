local moo = import "moo.jsonnet";
local lang = import "moo/cpp.jsonnet";
local candies = moo.object("candies", [
    moo.attribute("color", lang.types.string, "purple"),
    moo.attribute("count", lang.types.integer, 0),
]);
moo.object("eat", [
    moo.attribute("snack", candies),
])

  local moo = import "moo.jsonnet";
  local lang = import "moo/cpp.jsonnet";
  moo.object("candies", [
    moo.attribute("color", lang.types.string, "purple"),
    moo.attribute("count", lang.types.integer, 0),
  ], "A container full of yumminess")

// exercise the anys
local moo = import "moo.jsonnet";
local s = moo.oschema.schema("anys");
local hier = {
    any: s.any("VoidStar", doc="The Any type is any type you want"),

    count: s.number("Count", "u4"),
    email: s.string("Email", format="email", doc="Electronic mail address"),
    
    norm_one: s.oneOf("OneNumOrEmail", [self.count, self.email]),
    norm_all: s.allOf("AllNumOrEmail", [self.count, self.email]),
    norm_any: s.anyOf("AnyNumOrEmail", [self.count, self.email]),
};
moo.oschema.sort_select(hier)

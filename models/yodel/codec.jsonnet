local moo = import "moo.jsonnet";
local model = import "model.jsonnet";
{
    namespace: "mex",
    classname: "YodelCodec",
    fields : moo.fields(self.messages)
} + model

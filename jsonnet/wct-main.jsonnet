local protos_array = import "wct-proto.jsonnet";
local ifaces_array = import "wct-iface.jsonnet";
// assume proto and iface share exact name, if that fails, this
// mapping is where to fix it:
local protos = {[p.name]:p for p in protos_array};
local ifaces = {[i.name]:i for i in ifaces_array};
// fixme: sheesh, normalize these variable names here and in the templates....
local proto_ns = ["wct","pb"];

[
    {
        template: "protobuf3.j2",
        artifact: "wct.proto",
        params: {
            namespace: std.join(".", proto_ns),
            messages: protos_array,
        },
    },
    {
        template: "wct-pb-funcs.h.j2",
        artifact: "pbfuncs.h",
        params: {
            ifaces: ifaces_array,
            protons: std.join("::", proto_ns),
            protos: protos,
        }
    },
    {
        template: "wct-pb-funcs.cpp.j2",
        artifact: "pbfuncs.cpp",
        params: {
            ifaces: ifaces_array,
            protons: std.join("::", proto_ns),
            protos: protos,
            ifaces_byname: ifaces,
        }
    }
    
]

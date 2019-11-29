local wash_method(m) = m + {
    "auto" : if std.objectHas(m,"auto") then m.auto else false,
    "args" : if std.objectHas(m,"args") then m.args else "",
};
local wash_iface(i) = i + {
    methods: {[k]:wash_method(i.methods[k]) for k in std.objectFields(i.methods)},
};
local iface_array = [wash_iface(i) for i in import "wct-iface.jsonnet"];


local proto_ns = ["wct","pb"];
local proto_ns_cpp = std.join("::", proto_ns);
local wash_field(f) = f + {
    local stype = if std.type(f.type) == "string" then std.join("::", proto_ns + [f.type]) else f.type.cpp,
    local ff = {optional:false, repeated:false} + f,
    ctype: if ff.repeated then "std::vector<"+stype+">" else stype,
    type: if std.type(f.type) == "string" then f.type else f.type.pb,
    quals: if ff.repeated then "repeated" else if ff.optional then "optional" else "",
};
local wash_proto(p) = p {
    fields: [wash_field(f) for f in p.fields]
};

local proto_array = [wash_proto(p) for p in import "wct-proto.jsonnet"];





// assume proto and iface share exact name, if that fails, this
// mapping is where to fix it:
local proto_byname = {[p.name]:p for p in proto_array};
local iface_byname = {[i.name]:i for i in iface_array};



local source_params = {
    protos : {
        array: proto_array,
        byname: proto_byname,
    },
    ifaces: {
        array: iface_array,
        byname: iface_byname,
    },

    protons: std.join("::", proto_ns),
};
    



[
    {
        template: "protobuf3.j2",
        artifact: "wct.proto",
        params: {
            namespace: std.join(".", proto_ns),
            messages: proto_array,
        },
    },
    {
        template: "wct-pb-funcs.h.j2",
        artifact: "pbfuncs.h",
        params: source_params,
    },
    {
        template: "wct-pb-funcs.cpp.j2",
        artifact: "pbfuncs.cpp",
        params: source_params,
    }, 
    {
        template: "wct-pb-funcs-handmade.h.j2",
        artifact: "pbfuncs-handmade.h",
        params: source_params,
    }
    
]

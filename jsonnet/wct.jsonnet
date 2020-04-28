


// convert from general data type to specific
local types = {
    int32: { pb: "int32", cpp: "int32_t" },
    float: { pb: "float", cpp: "float" },
    double: { pb: "double", cpp: "double" },
    string: { pb: "string", cpp: "std::string" },
};

local pbtype(f) = {
    pbtype: if std.objectHas(types, f.type) then types[f.type].pb else f.type,
};

local cpptype(f) = {
    shunt: std.objectHas(types, f.type),
    cpptype: if self.shunt then types[f.type].cpp else f.type,
    cppfull: if f.repeated then "std::vector<"+self.cpptype+">" else self.cpptype,
};

// regularize data for use modeling interface 
local wash_iface_field(f) = f + pbtype(f) + cpptype(f);

local wash_iface(i) = i + {
    fields: [wash_iface_field(f) for f in i.fields],
    methods: [wash_iface_field(f) for f in i.methods]
};

local ifaces = [wash_iface(i) for i in import "wct-data.jsonnet"];

{
    ifaces: [ifaces[std.length(ifaces)-1]],        // for testing templates just take first
    namespace : {
        lst: ["wct","pb"],
        cpp: std.join("::", self.lst),
        pb:  std.join(".",  self.lst),
    },
}


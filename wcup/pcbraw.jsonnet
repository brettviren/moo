// model a Wire-Cell Toolkit User Package (wcup) for PCB Raw data code
local moo = import "moo.jsonnet";

local name="Pcbro";
local fullname = "WireCell"+name;

local components = [ {
    classname: "RawSource",
    typename: name+self.classname,
}];

local models = {
    base: {
        capname: name,
        fullname: fullname,
        deps: ['WireCellUtil', 'WireCellIface', 'WCT', 'JSONCPP', 'SPDLOG'],
        namespace: std.asciiLower(name),
    },
} + { [c.classname]:models.base+c for c in components };

[
    moo.render(models.base, "wscript.j2", "wscript"),
    moo.render(models.base, "README.org.j2", "README.org"),
    moo.render(models.RawSource, "class.cxx.j2", "src/RawSource.cxx"),
    moo.render(models.RawSource, "class.h.j2", "inc/WireCellPcbro/RawSource.h"),
    moo.render(models.RawSource, "test_class.cxx.j2", "test/test_RawSource.cxx"),
]

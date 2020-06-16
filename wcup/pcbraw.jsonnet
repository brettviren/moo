// model a Wire-Cell Toolkit User Package (wcup) for PCB Raw data code

local wcup = {
    target(path, model, template, schema="") :: {
        path:path, model:model, template:template, schema:schema
    },
    
    
};

local name="Pcbro";
local fullname = "WireCell"+name;

local components = [ {
    classname: "RawSource",
    typename: name+self.classname,
}];

{
    targets: [
        wcup.target("wscript", "base", "wscript"),
        wcup.target("README.org", "base", "readme"),]
        + [wcup.target("src/%s.cxx"%c.classname,
                       c.classname,"classcxx")
           for c in components]
        + [wcup.target("inc/%s/%s.h"%[fullname,c.classname],
                       c.classname,"classh")
           for c in components]
        + [wcup.target("test/test_%s.cxx"%c.classname,
                       c.classname,"testclass")
           for c in components],
    
    models: {
        base: {
            capname: name,
            fullname: fullname,
            deps: ['WireCellUtil', 'WireCellIface', 'WCT'],
            namespace: std.asciiLower(name),
        },
    } + { [c.classname]:$.models.base+c for c in components },
    templates: {
        wscript: "wscript.j2",
        readme: "README.org.j2",
        classh: "class.h.j2",
        classcxx: "class.cxx.j2",
        classinline: "classinline.cxx.j2",
        testclass: "test_class.cxx.j2",
    },
    schema: {
        // none for now
    },
}

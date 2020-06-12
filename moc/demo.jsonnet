// Schema and some demo configuration for specific components of a node

local moc = import "moc.jsonnet";
local re = import "re.jsonnet";

{
    
    schema(s):: {
        local ident = s.string(pattern=re.ident_only),
        local source = s.record("Source", fields=[
            s.field("ntosend", s.number(dtype="i4"), -1,
                    doc="Number of messages to source, negative means run forever"),
        ], doc="A config for a source component"),

        local cfghdr = s.record("ConfigHeader", fields=[
            s.field("impname", ident), s.field("instname", ident)]),

        types: [ cfghdr, source ],
    },

    avro: self.schema(moc.avro).types,
    nljs: {   
        // Template is written to take Avro schema for types
        types:$.avro,
        // Fixme: this value here represents a semantic sheer.
        namespace:"moc",
        // Fixme: this value here represents a semantic sheer.
        name: "demo",
    },
    jscm: self.schema(moc.jscm).types,


    // An example configuration object.  Fixme: can we generate a set
    // of Jsonnet functions to call instead of typing literal data
    // structure so that we may have valid-by-construction
    // configuration objects?
    demo: {

        local node = {
            ident: "mynode1",
            portdefs: [{
                ident:"src",
                links: [{
                    linktype: "bind",
                    address: "" // default bind
                }],
            }],
            compdefs: [{
                ident: "mysource1",
                type_name: "MySource",
                portlist: ["src"],
                config: "MySource::mysource1 config string",
            }]
        },

        local source = {
            ntosend: 10
        },

        // 
        asarray: [
            {impname:"MySource",instname:"mysource1"}, source,
            {impname:"Node",instname:"mynode1"}, node,
        ],

        // Use moo compile --string [...]
        stream: std.join('\n',[std.manifestJson(o) for o in self.asarray])
    }
}

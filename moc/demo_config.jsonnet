// Define some demo config types
local avro = import "avro.jsonnet";
local am = avro.model;

{
    // JSON Schema describing valid demo config modes.
    schema: {},

    // Helper methods to produce valid demo config models and some
    // models themselves.
    model: {

        junk: am.enum("addrtype", ["direct","discover"], default="direct"),



        // A linkdef describes all possible ways to make a single link
        linkdef: am.record("linkdef", namespace="moc.demo.config",
                           fields=[
                               am.field("linktype", am.enum("linktype", ["bind","connect"], default="bind"),
                                        doc="The socket may bind or connect the link"),

                               am.field("addrtype", am.enum("addrtype", ["direct","discover"], default="direct"),
                                        doc="Determin how the address string is to be interpreted"),
                               am.field("address", am.string, 
                                        doc="The address to link to")
                           ],
                           doc="Describes how a single link is to be made"),

        // A portdef describes the port configuration object 
        portdef: am.record("portdef", namespace="moc.demo.config",
                           fields=[
                               am.field("ident", am.string,
                                        doc="Identify the port uniquely in th enode"),
                               am.field("links", am.array($.model.linkdef), 
                                        doc="Describe how this port should link to addresses"),
                           ],
                           doc="A port configuration object",),

        // A compdef describes the component configuration object
        compdef: am.record("compdef", namespace="moc.demo.config",
                           fields=[
                               am.field("ident", am.string, 
                                        doc="Identify copmponent instance uniquely in the node"),
                               am.field("typename", am.string, 
                                        doc="Identify the component implementation"),
                               am.field("portlist", am.array(am.string), 
                                        doc="Identity of ports required by component"),
                               am.field("config", am.string, 
                                        doc="Configuration data specific to the component instance and encoded for the component implementation")
                           ],
                           doc="An object used by the node to configure a component"),
        
        // A node is a collection of ports and components that may use
        // those ports.  A node base configuration class has
        // attributes which give enough info to instantiate and apply
        // configuration to components
        node: am.record("node", namespace="moc.demo.config",
                        fields=[
                            am.field("ident", am.string, 
                                     doc="Idenfity the node instance"),
                            am.field("portdefs", am.array($.model.portdef), 
                                     doc="Define ports on the node to be used by components"),
                            am.field("compdefs", am.array($.model.compdef),
                                     doc="Define components the node should instantiate and configure"),
                        ],
                        doc="A node configures ports and components"),
        

        // A source configure class
        source: am.record("source", namespace="moc.demo.config",
                          fields=[
                              am.field("ntosend", am.int, -1,
                                       doc="Number of messages to source, negative means run forever"),
                          ], doc="A config for a source component"),
        
    },

    // Here define some configuration object instances.
    objects: {

        // an instance of a node 
        mynode: {
            ident: "mynode1",
            ports: [{
                ident:"src",
                links:[{
                    linktype: "bind",
                    addrtype: "direct",
                    address: "" // default bind
                }],
            }],
            comps: [{
                ident: "mysource1",
                typename: "MySource",
                portlist: ["src"],
                config: std.manifestJson($.objects.mysource),
            }]
        },

        // an instance of a model.source
        mysource: {
            ntosend: 10
        },
    }
}

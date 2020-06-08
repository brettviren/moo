// Define some demo config types
local avro = import "avro.jsonnet";
local am = avro.model;

// apparently avro only lets us have namespace one level deep.
local namespace="moc";

{
    // JSON Schema describing valid demo config modes.
    schema: {},

    // Helper methods to produce valid demo config models and some
    // models themselves.
    model: {

        linktype: am.enum("LinkType", ["bind","connect"], default="bind",
                          namespace=namespace),

        addrtype: am.enum("AddrType", ["direct","discover"], default="direct",
                          namespace=namespace),

        // A linkdef describes all possible ways to make a single link
        linkdef: am.record("Link",
                           namespace=namespace,
                           fields=[
                               am.field("linktype",
                                        "LinkType",
                                        doc="The socket may bind or connect the link"),

                               am.field("addrtype",
                                        "AddrType",
                                        doc="Determine how the address string is to be interpreted"),

                               am.field("address", am.string, 
                                        doc="The address to link to")
                           ],
                           doc="Describes how a single link is to be made"),

        // A portdef describes the port configuration object 
        portdef: am.record("Port",
                           namespace=namespace,
                           fields=[
                               am.field("ident", am.string,
                                        doc="Identify the port uniquely in th enode"),
                               am.field("links",
                                        am.array("Link"), 
                                        //am.array($.model.linkdef), 
                                        doc="Describe how this port should link to addresses"),
                           ],
                           doc="A port configuration object",),

        // A compdef describes the component configuration object
        compdef: am.record("Comp",
                           namespace=namespace,
                           fields=[
                               am.field("ident", am.string, 
                                        doc="Identify copmponent instance uniquely in the node"),
                               am.field("type_name", am.string, 
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
        node: am.record("Node",
                        namespace=namespace,
                        fields=[
                            am.field("ident", am.string, 
                                     doc="Idenfity the node instance"),
                            am.field("portdefs",
                                     //am.array($.model.portdef), 
                                     am.array("Port"), 
                                     doc="Define ports on the node to be used by components"),
                            am.field("compdefs",
                                     //am.array($.model.compdef),
                                     am.array("Comp"),
                                     doc="Define components the node should instantiate and configure"),
                        ],
                        doc="A node configures ports and components"),
        

        nljs : {
            namepath: std.split(namespace, '.'),
            types: $.model.avro,
        },
        avro:[
            $.model.linktype,
            $.model.addrtype,
            $.model.linkdef,
            $.model.portdef,
            $.model.compdef,
            $.model.node,
        ],

    },
    app: {
        // A source configure class
        source: am.record("Source",
                          namespace=namespace,
                          fields=[
                              am.field("ntosend", am.int, -1,
                                       doc="Number of messages to source, negative means run forever"),
                          ], doc="A config for a source component"),
        
        proxy: am.record("Proxy",
                         namespace=namespace,
                         fields=[
                             am.field("iports", am.array(am.string),
                                      doc="Array of input port names"),
                             am.field("oports", am.array(am.string),
                                      doc="Array of output port names"),
                         ]),
        sink: am.record("Sink",
                        namespace=namespace,
                        fields=[],
                        doc="A sink component"),
        nljs : {
            namepath: std.split(namespace, '.'),
                        types: $.app.avro,
        },
        avro: [
            $.app.source,
            $.app.proxy,
            $.app.sink,            
        ]
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
                type_name: "MySource",
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

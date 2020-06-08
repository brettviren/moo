// model oriented configuraiton
local moo = import "moo.jsonnet";
//local ms = moo.schema;

local re = {

    // Basic identifier (restrict to legal C variable nam)
    ident: '[a-zA-Z][a-zA-Z0-9_]*',
    // DNS hostname
    dnslabel: '([a-zA-Z0-9][a-zA-Z0-9\\-]*[^-])+',
    dnshost: '(\\*)|(%s(\\.%s)*)' % [re.dnslabel, re.dnslabel],
    // URIs are either of the zeromq type:
    // - tcp://host:port
    tcpport: '(:(\\*)|([0-9]+))?',
    tcp: '^tcp://' + re.dnshost + re.tcpport + '$',
    hiername: '[^/\\| ]+',
    hierpath: '/?(%s/?)+' % re.hiername,
    // - ipc://filename.ipc
    ipc: '^ipc://' + re.hierpath + '$',
    // - inproc://label
    inproc: '$inproc://' + re.hiername + '$',

    // or for auto connect via Zyre discovery
    // - zyre://nodename/portname[?header=value]
    //
    // Node names are not (necessarily) hostnames and may be liberally
    //defined as anything not looking like a URI delim.
    //nodename: '[^#:/\\?]+',
    nodename: '[^/]+',
    // Likewise port names
    portname: '[^/]+',
    // we'll let zyre also match on arbitrary headers
    param: '(\\?%s=%s(&%s=%s)*)?' % [re.ident for n in std.range(0,3)],
    zyre: '^zyre://%s/%s%s$' % [re.nodename, re.portname, re.param],

    uri: std.join('|', [re.tcp, re.ipc, re.inproc, re.zyre]),

    // match an instance name for a component
    compname: re.ident,
    // match a "typename" for a component
    comptype: re.ident,
};

{

    re: re,


    // A JSON Schema for configuration objects    
    schema : {
        // reused elements
        definitions: {

            address: ms.string(pattern=re.uri),
            nodename: ms.string(pattern=re.nodename),
            portname: ms.string(pattern=re.portname),
            compname: ms.string(pattern=re.compname),
            comptype: ms.string(pattern=re.comptype),

            // How a port links to an address
            linkdef: ms.object({
                // A link may bind or connect
                linktype: ms.enum(["bind","connect"]),
                // Address is a URI of restricted spelling
                address: ms.def("address"),
            },["linktype","address"]),

            // Define a node port
            portdef: ms.object({
                // Identify the port uniquely in the node.
                ident: ms.def("portname"),
                // Methods to link this port to an address
                links: ms.array(ms.def("linkdef")),
                // Description.
                doc: ms.string(),
            },["ident","links"]),

            // Define a component
            compdef: ms.object({
                // Instance name
                ident: ms.def("compname"),
                // Symbol used to retrieve instance from factory
                typename: ms.def("comptype"),
                // List of portnames required by the instance
                portlist: ms.array(ms.string()),
                // Description
                doc: ms.string(),

                // Instance config in typename-specific schema.
                config: true,

            },["ident","typename"]),

            // Define a node
            nodedef: ms.object({
                // Instance name
                ident: ms.def("nodename"),
                // Port definitions
                portdefs: ms.array(ms.def("portdef")),
                // Component definitions
                compdefs: ms.array(ms.def("compdef")),
                // Description
                doc: ms.string(),
            },["ident","compdefs"]),
        },                      // definitions

    },

    model:  {
        
        classes : [
            
        ],

    },

    test: {
        compname: 'a0b_Z',
        tcp: 'tcp://*:*',
        tcp2: 'tcp://a9-b.ccc:444',
        ipc: 'ipc:///abs/path.ext-_',
        zyre: 'zyre://my-first.true/love?not=really',

        node: {
            ident: "node1",
            portdefs: {
                ident: "port1",
                links: [ {
                    linktype: "bind",
                    address: "tcp://*:*",
                }]
            },
            compdefs: [{
                ident: "comp1",
                typename: "TestSrc",
                portlist: ["port1"],
            }],
            doc: "Configure for node1"
        }
    }
}

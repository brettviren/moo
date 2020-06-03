// This document defines a schema to validate a model of a configuration object.


local moo = import "moo.jsonnet";
local ms = moo.schema;
local objif = moo.objif;
local ct(typename, rest={}, req=[]) =
    ms.object({
        // A type name is required
        typename:ms.const(typename),
        // names of ports that the app should supply to the component
        ports:ms.array(ms.string())
    } +rest, ["typename"]+req);

{
    schema: {

        // Linkages are ways for a port to bind or connect to an address.
        linkages: [

            // Binds

            // An explicit bind ZeroMQ address string
            ms.object({
                ltype: ms.const("bind"),
                address: ms.string(format='uri'),
            }, ["ltype","address"]),

            // A bind only for TCP transport on specific host name and
            // TCP port number.
            ms.object({
                ltype: ms.const("bind"),
                // Identify the NIC based on hostnam or IP address.
                // If no host is given, the default NIC is assumed.
                host: ms.oneOf([ms.string(format="ipv4"),
                                ms.string(format="ipv6"),
                                ms.string(format="hostname")]),
                // TCP port number, not a component "port".  An
                // unspecified or zero portnum indicates first
                // available portnum is to be used.
                portnum: ms.integer()
            }, ["ltype"]),


            // connects

            // An explicit connect to a ZeroMQ address string
            ms.object({
                ltype: ms.const("connect"),
                address: ms.string(format='uri'),
            }, ["ltype","address"]),


            // A connect via abstract node and port names
            ms.object({
                ltype: ms.const("connect"),
                nodename: ms.string(),
                portname: ms.string(),                
            }),
            
        ],

        // A port is a sink and/or source of messages
        port: ms.object({
            // An identifier unique at least across all ports of all
            // components used by the application.
            ident: ms.string(),

            // A socket type is specified as an enum of ZeroMQ socket
            // names, lowercased.
            stype : ms.enum(moo.zmq.socket.names),

            // A number of links may be specified and each may be
            // specified in one of several ways.
            links: ms.array(ms.oneOf($.schema.linkages)),
        }, ["ident", "stype"]),

        // A component is some portion of an application (usually
        // implemented as a factory constucted object)
        component : ms.object({
            // every component has an instance name unique at least to the app
            ident: ms.string(),
            // configuration specific to the component type
            typeconfig: ms.oneOf($.schema.known_component_types)
        }, ["ident","typeconfig"]),

        application: ms.object({
            // An application have a name by which it is uniquely known
            ident: ms.string(),
            // An application may have a set of ports.  
            portset: ms.array(ms.array($.schema.port)),
            plugins: ms.array(ms.string()),
            components: ms.array($.schema.component),
        }, ["ident"]),

        known_component_types : [

            ct("TestSource", {nmessages: ms.integer()}, ["nmessages"]),
            ct("TestFanout", {inport: ms.string()}, ["inport"]),
            ct("TestFanin", {outport: ms.string()}, ["outport"]),
            ct("TestSink")
            
        ],

    },

    types: {
        application(ident, components=[], plugins=[], portset=[]) :: {
            ident: ident, components: components, plugins:plugins,
            portset:portset
        },

        component(ident, typeconfig) :: {
            ident:ident, typeconfig:typeconfig
        },

        // Create a bind to any zeromq address
        bind(addr) :: {
            ltype:"bind",
            address: addr,
        },
        // Create a bind for TCP to a optional host and port
        bind_tcp(host=null, port=0) :: {
            ltype:"bind",
            port:port,
        } + objif("host",host),

        // Create a connect to any zeromq address
        connect(addr) :: {
            ltype:"connect",
            address:addr
        },

        // Create a connect that will auto connect via discovery
        connect_auto(nodename, portname) :: {
            ltype:"connect",
            nodename: nodename,
            portname: portname,
        },

        port(ident, stype, links=[]) :: {
            ident:ident, stype:stype, links:links
        },

        test_source(ident, nmsg, ports) :: {
            ident: ident,
            typeconfig: {
                typename: "TestSource",
                nmessages: nmsg,
                ports: ports
            }
        }
    }
}

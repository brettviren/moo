// This document defines a schema to validate a model of a configuration object.

local moo = import "moo.jsonnet";
local ms = moo.schema;
local objif = moo.objif;

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

        // A component from the point of view of an application
        use_component: ms.object({

            // every component has an instance name unique at least to the app
            ident: ms.string(),

            // A name path locates the component impementation.  The
            // final entry is typically assumed to be a class name and
            // prior entries are, eg, a C++ namespace or Python module
            // path.  This must match what is used for a def_component
            namepath:ms.array(ms.string()),

            // names of ports that the app should supply to the component
            ports:ms.array(ms.string())
        }, ["ident","codename")),

        application: ms.object({
            // An application have a name by which it is uniquely known
            ident: ms.string(),
            // An application may have a set of ports.  
            portset: ms.array($.schema.port),
            plugins: ms.array(ms.string()),
            components: ms.array($.schema.use_component),
        }, ["ident"]),

        // define schema for component implementation 
        def_component(namepath, scheme) :: ms.object({
            
            // A component is located, eg for a C++ namespace or
            // Python module.  The last element of the path must be
            // usable as a class name.
            namepath: namepath,

        }, ["namepath"]), ms.object(scheme, std.objectFields(scheme))

        known_component_types : [

            typcfg("TestSource", {nmessages: ms.integer()}, ["nmessages"]),
            typcfg("TestFanout", {inport: ms.string()}, ["inport"]),
            typcfg("TestFanin", {outport: ms.string()}, ["outport"]),
            typcfg("TestSink")
            
        ],

    },

}


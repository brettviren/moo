// This document defines a suite of configuration objects that follow
// the moc schema.

local moo = import "moo.jsonnet";
local moc = import "schema.jsonnet";
local objif = moo.objif;
local mt = {
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

    demo : {
        source(ident, nmsg, ports) :: {
            ident: ident,
            namepath: ["moc","demo","source"],
            typeconfig: {
                codename: "MocDemoSource",
                nmessages: nmsg,
                ports: ports
            }
        }
    }
};


{
    schema: moo.schema.object({
        apps:moo.schema.array(moc.schema.application)}, ["apps"]),
    

    // Make a configuration
    model: {
        apps: [
            mt.application(
                "app1",
                components = [
                    mt.demo.source("ts1", 10, ["src1"]),
                ],
                portset = [
                    mt.port("src1", "push", mt.connect_auto("app2","snk1"))
                ])
        ]
    }
    

}

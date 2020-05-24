local moo = import "moo.jsonnet";
local ms = moo.schema;
local mt = moo.types;

local defs = {

    role : ms.object({
        name : ms.enum(["producer","consumer","broker"]),
        ident : ms.string(),
    }, "role"),
    
    link : ms.oneOf( [
        {
            method:"bind",
            address: ms.oneOf( [
                {
                    host : ms.oneOf([ms.string(format="ipv4"),
                                         ms.string(format="hostname")]),
                    port : ms.integer()
                },
                {
                    url : ms.string(format="uri"),
                },
                null
            ]),
        },
        {
            method: "connect",
            address: ms.oneOf([
                {
                    nodename : ms.string(),
                    portname : ms.string()
                },
                {
                    url: ms.string(format="uri"),
                }
            ])
        }
    ], "link"),

    port : ms.object({
        ident : ms.string(),
        links : ms.array(ms.def("link"))
    }, "port"),

    producer : ms.object({
        role: ms.def("role"),
        ports: ms.object({
            output: ms.def("port")
        }),
    }),

    consumer : ms.object({
        role: ms.def("role"),
        ports: ms.object({
            input: ms.def("port")
        }),
    }),

    broker : ms.object({
        role: ms.def("role"),
        ports: ms.object({
            input: ms.def("port"),
            output: ms.def("port")
        }),
    })
};

local body = ms.array(ms.anyOf([
    ms.def(n) for n in ["producer", "consumer", "broker"]]));
                         


{
    schema: ms.schema(body, defs, 
                      id = "https://brettviren.github.io/moo/schema/pbc.json",
                      version="draft-07"),

    types:: mt {
        hostport(tcphost, tcpport) :: {host:tcphost,
                                       port:$.types.integer(tcpport)},
        nodeport(nodename, portname) :: {nodename:nodename, portname:portname},
        link(method, address=null) :: { method:method, address:address},
        port(ident, links) :: {ident:ident, links:links},
        role(name, ports) :: {name:name, ports:ports},
        roleinst(ident, role) :: role { ident:ident },


        producer(name, output) ::
        mt.roleinst(name, mt.role("producer", { output: output})),
                    
        consumer(name, input) ::
        mt.roleinst(name, mt.role("consumer", { input: input})),

        broker(name, input, output) ::
        mt.roleinst(name, mt.role("consumer", { input: input, output:output})),
    }
}

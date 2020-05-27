local moo = import "moo.jsonnet";
local ms = moo.schema;
local mt = moo.types;

local defs = {

    role : ms.object({
        name : ms.enum(["producer","consumer","broker"]),
        ident : ms.string(),
    }),
    
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
    ]),

    port : ms.object({
        ident : ms.string(),
        links : ms.array(defs.link)
    }),

    producer : ms.object({
        role: defs.role,
        ports: ms.object({
            output: defs.port
        }),
    }),

    consumer : ms.object({
        role: defs.role,
        ports: ms.object({
            input: defs.port
        }),
    }),

    broker : ms.object({
        role: defs.role,
        ports: ms.object({
            input: defs.port,
            output: defs.port
        }),
    })
};


{
    defs :: defs,

    schema: std.prune(ms.schema(ms.array(ms.anyOf([defs.producer, defs.consumer, defs.broker])), version="draft-07")),

    types: mt  {
        hostport(tcphost, tcpport) :: {host:tcphost,
                                       port:$.types.integer(tcpport)},
        nodeport(nodename, portname) :: {nodename:nodename, portname:portname},
        link(method, address=null) :: { method:method, address:address},
        port(ident, links) :: {ident:ident, links:links},
        role(name, ports) :: {name:name, ports:ports},
        roleinst(ident, role) :: role { ident:ident },


        producer(name, output) ::
        self.roleinst(name, self.role("producer", { output: output})),
                    
        consumer(name, input) ::
        self.roleinst(name, self.role("consumer", { input: input})),

        broker(name, input, output) ::
        self.roleinst(name, self.role("consumer", { input: input, output:output})),
    }
}


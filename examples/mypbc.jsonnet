local moo = import "moo.jsonnet";
local mt = moo.types;
local pbc = import "pbc.jsonnet";

[
    pbc.producer("myproducer",
                 [mt.link("connect", "tcp://brokerhost:3456")]),

    pbc.consumer("myconsumer",
                 [mt.link("connect",mt.nodeport("mybroker","output"))]),

    pbc.broker("mybroker",
               [mt.link("bind")],
               [mt.link("bind",
                        mt.hostport("broker.example.com", 5678))])
]

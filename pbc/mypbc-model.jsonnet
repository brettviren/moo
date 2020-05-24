local moo = import "moo.jsonnet";
local schema = import "schema.jsonnet";
local mt = schema.types;


[
    mt.producer("myproducer",
                [mt.link("connect", "tcp://brokerhost:3456")]),

    mt.consumer("myconsumer",
                [mt.link("connect",mt.nodeport("mybroker","output"))]),

    mt.broker("mybroker",
              [mt.link("bind")],
              [mt.link("bind",
                       mt.hostport("broker.example.com", 5678))])
]

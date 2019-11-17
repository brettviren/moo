// -*- jsonnet -*-

local messages = import "ptmp-proto-v0.jsonnet";

{
    template: "protobuf.j2",
    artifact: "ptmp.proto",
    renderer: "protobuf",
    params: {
        syntax: "proto2",
        namespace: "ptmp.data",
        messages: messages,
    },
}

    

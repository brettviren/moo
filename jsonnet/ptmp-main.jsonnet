
local pb = import "ptmp-proto-v0.jsonnet";
local zmq = import "ptmp-zmq-v0.jsonnet";

[
    {
        template: "classes.plantuml.j2",
        artifact: "ptmp-msg-classes.plantuml",
        params: {
            messages: [m {namespace: "pb"} for m in pb]
                + [m {namespace: "zmq"} for m in zmq],
        },
    },
    {
        template: "protobuf.j2",
        artifact: "ptmp.proto",
        params: {
            syntax: "proto2",
            namespace: "ptmp.data",
            messages: pb,
        },
    }
]

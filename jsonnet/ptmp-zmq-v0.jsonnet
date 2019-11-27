// -*- jsonnet -*-

// Model ZeroMQ level messages for ptmp schema v0.

[
    {
        name: "ptmp",
        comment: "PTMP message",
        fields: [ {
            name: "version",
            type: "int32",
            comment: "A number indicating version of the rest of the message.",
        }, {
            name: "payload",
            type: "TPSet",
            comment: "The serialized ptmp.data.TPSet",
        }]
    },
]
        

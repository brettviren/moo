// this models WCT data interfaces.
//
// It essentially mimics PB but all are required by default.
[
    {
        name: "Trace",
        comment: "Charge vs time waveform on a channel",
        fields: [
            {
                type: "int32",
                name: "channel",
                comment: "Identifier of channel associated with this waveform",
            }, {
                type: "int32",
                name: "tbin",
                comment: "Time bin relative to some time at which the first element of the charge array is to be taken",
            }, {
                type: "float",
                name: "charge",
                comment: "Contiguous charge measure on the channel starting at tbin",
                repeated: true
            }
        ]
    },
    {
        name: "ChannelMask",
        comment: "A channel ranges of samples",
        fields: [
            {
                type: "int32",
                name: "channel",
                comment: "The channel identifier",
            },
            {
                type: "int32",
                name: "begtick",
                comment: "Array of begin tick indices (right open)",
                repeated: true,
            },
            {
                type: "int32",
                name: "endtick",
                comment: "Array of end tick indices (right open)",
                repeated: true,
            },
        ],
    },
    {
        name: "TaggedChannelMasks",
        comment: "Associate a tag with a collection of ChannelMasks",
        fields: [
            {
                type: "string",
                name: "tag",
                comment: "A string providing some hint as to the semantic meaning of the channel masks",
            },
            {
                type: "ChannelMask",
                name: "masks",
                comment: "A collection of channel masks",
                repeated: true,
            },
        ]
    },
    {
        name: "TraceInfo",
        comment: "Meta data information about a group of traces in the context of a frame",
        fields: [
            {
                type: "string",
                name: "tag",
                comment: "The tag identifier on this group of traces",
            },
            {
                type: "int32",
                name: "indices",
                comment: "Indices into a trace collection of this group",
                repeated: true,
            },
            {
                type: "double",
                name: "summary",
                comment: "An array with elements corresponding to indices of some value",
                repeated: true,
                optional: true, // in pb, this is redunant.
            }
        ],
    },
    {
        name: "Frame",
        comment: "A collection of traces and associated meta data",
        fields: [
            {
                type: "int32",
                name: "ident",
                comment: "An identifier for the frame"
            },
            {
                type: "float",
                name: "time",
                comment: "An absolute time from which trace tbin are relative",
            },
            {
                type: "float",
                name: "tick",
                comment: "The sampling period",
            },
            {
                type: "Trace",
                name: "traces",
                comment: "Ordered collection of all traces in the frame",
                repeated: true,
            },
            {
                type: "string",
                name: "frame_tags",
                comment: "Array of tag strings associated with the frame",
                repeated: true,
            },
            {
                type: "string",
                name: "trace_tags",
                comment: "Array of all tag strings associated with traces in the frame",
                repeated: true,
            },
            {
                type: "TraceInfo",
                name: "trace_info",
                comment: "Collection of meta data info about groups of traces",
                repeated: true,
            },
            {
                type: "TaggedChannelMasks",
                name: "cmm",
                comment: "A colelection of tagged channel masks",
                repeated: true,
            }
        ]
    },
]

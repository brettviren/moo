// Model WCT data structures (data interface class and PB object
// representation).  A structure is modeled as a number of fields.
// Each field corresponds to what might be a C++ class data member or
// a PB object in a .proto file. 


// If a type is string then it must be simple in the sense that the
// C++ data member may be set by calling a PB object method of the
// same name and the PB object set_<name> can be called on the C++
// data member.  The type may be more complex.
local map(keytype, valtype) = {
    collection: "dictionary", keytype:keytype, valtype:valtype
};
local array(valtype) = {
    collection: "sequence", valtype: valtype,
};
local struct(name) = {
    collection: "structure", structype: name,
};
local field(type,name,comment) = {
    type:type, name:name, comment:comment,
};

// A structure may also have methods which will be added to the C++
// class with their implementation left to manual coding.
local method(return,name,args,comment) = {
    return:return, name:name, args:args, comment:comment,
};

[{
    name: "Trace",
    comment: "A waveform segment",
    interface: true,
    fields: [
        field("int32","channel",
              "ID of the channel from whence the trace derived"),
        field("int32","tbin",
              "Sample count at which the trace begins"),
        field(array("float"),"charge",
              "An array of samples comprising the trace"),
    ],
},{
    name: "ChannelMask",
    comment: "A channel ranges of samples",
    interface: false,
    fields: [
        field("int32", "channe",
              "The channel identifier"),
        field(array("int32"), "begtick",
              "Array of begin tick indices (right open)"),
        field(array("int32"), "endtick",
              "Array of end tick indices (right open)"),
    ],
}, {
    name: "TaggedChannelMasks",
    comment: "Associate a tag with a collection of ChannelMasks",
    interface: false,
    fields: [
        field("string", "tag",
              "Semantic label on channel masks"),
        field(array(struct("ChannelMask")), "masks",
              "A collection of channel masks"),
    ]        
}, {
    name: "TraceInfo",
    comment: "Meta data information about a group of traces in the context of a frame",
    interface: false,
    fields: [
        field("string", "tag",
              "The tag identifier on this group of traces"),
        field(array("int32"), "inices",
              "Indices into a trace collection of this group"),
        field(array("double"), "summary",
              "Values corresponding tagged traces")
    ],
}, {
    name: "Frame",
    comment: "A collection of traces and associated meta data",
    interface: true,
    fields: [
        field("int32", "ident",
              "An identifier for the frame"),
        field("float", "time",
              "An absolute time from which trace tbin are relative"),
        field("float", "tick",
              "The sampling period"),
        field(array(struct("Trace")), "traces",
              "Ordered collection of all traces in the frame"),
        field(array("string"), "frame_tags",
              "Array of tag strings associated with the frame"),
        field(array("string"), "trace_tags",
              "Array of all tags associated with traces in the frame"),
        field(map("string", struct("TraceInfo")), "trace_info",
              "Collection of meta data info about groups of traces"),
        field(array(struct("TaggedChannelMasks")), "tcm",
              "A collection of tagged channel masks"),
    ],
    // pure methods
    methods: [
        method("const WireCell::IFrame::trace_list_t&", "tagged_traces",
               "const tag_t& tag",
               "Trace indices associated with tag"),
        method("const WireCell::IFrame::trace_summary_t&", "trace_summary",
               "const tag_t& tag",
               "Trace summary for a given tag"),
    ]
    
}]


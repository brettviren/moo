// This models the methods required by WCT data interface classes

[
    {
        name: "Trace",
        comment: "Interface to info about one trace",
        methods: {
            channel : {
                return: "int",
                comment: "Return the identifier for the associated channel",
                auto: "attribute",
            },
            tbin: {
                return: "int",
                comment: "Return the tbin",
                auto: "attribute",
            },
            charge : {
                return: "const std::vector<float>&",
                comment: "Access the ADC/charge waveform starting at tbin",
            }
        }
    },
    {
        name: "Frame",
        comment: "A set of traces and associated metadata",
        methods: {
            frame_tags:  {
                return: "const WireCell::IFrame::tag_list_t&",
                comment: "Tags on the frame",
            },
            trace_tags:  {
                return: "const WireCell::IFrame::tag_list_t&",
                comment: "Union of all sets of tags on traces",
            },
            tagged_traces: {
                return: "const WireCell::IFrame::trace_list_t&",
                comment: "Trace indices with given tag",
                args: "const tag_t& tag",
            },
            trace_summary: {
                return: "const WireCell::IFrame::trace_summary_t&",
                comment: "Trace summary for given tag",
                args: "const tag_t& tag",
            },
            traces: {
                return: "WireCell::ITrace::shared_vector",
                comment: "All traces",
            },
            masks: {
                return: "WireCell::Waveform::ChannelMaskMap",
                comment: "Channel mask map",
            },
            ident: {
                return: "int",
                comment: "Numerical identifier for this frame",
                auto: "attribute",
            },
            time: {
                return: "double",
                comment: "Absolute reference time",
                auto: "attribute",
            },
            tick: {
                return: "double",
                comment: "Sampling time",
                auto: "attribute",
            },
        },
    }
]


// Variant patterns to consider supporting:
// - the imple name may not match the iface name nor the pb name

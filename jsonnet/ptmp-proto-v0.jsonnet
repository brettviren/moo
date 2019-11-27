// -*- jsonnet -*-
//
// Model message used in ptmp.proto v0
//
// A field is optional unless required is true.
// A field is scalar unless repeated is true.
[
    {
        name: "TrigPrim",
        comment: "A trigger primitive (TP) represents a period of signal above threshold on a channel",
        fields: [ {
            name: "channel",
            type: "uint32",
            comment: "The channel identifier unique in some scope",
            required: true,
        }, {
            name: "tstart",
            type: "uint64",
            comment: "The absolute hardware clock count of the start of the TP",
            required: true,
        }, {
            name: "tspan",
            type: "uint32",
            comment: "The relative hardware clock count of the duration of the TP",
        }, {
            name: "adcsum",
            type: "uint32",
            comment: "The sum of ADC above threshold in the TP",
        }, {
            name: "adcpeak",
            type: "uint32",
            comment: "The peak ADC value of the TP",
        }, {
            name: "flags",
            type: "uint32",
            comment: "A bit mask erorr flag, 0 is no error",
        }],
    }, {
        name: "TPSet",
        comment: "A set of TrigPrims",
        fields: [{
            name: "count",
            type: "uint32",
            comment: "A sequential count of how many TPSets were sent before this one.",
            required: true,
        }, {
            name: "detid",
            type: "uint32",
            comment: "Identify the detector portion that this TPSet derives.",
            required: true,
        }, {
            name: "created",
            type: "int64",
            comment: "The system time stamp in microseconds from Unix Epoch when this TPSet was created just prior to sending.",
            required: true,
        }, {
            name: "tstart",
            type: "uint64",
            comment: "The the hardware clock count for which the span of the set is considered to start.",
            required: true,
        }, {
            name: "tspan",
            type: "uint32",
            comment: "The hardware clock count for which this set is considered to span.",
            required: false,
        }, {
            name: "chanbeg",
            type: "uint32",
            comment: "The channel ident providing the lower bound on the set, inclusive",
            required: false,
        }, {
            name: "chanend",
            type: "uint32",
            comment: "The channel ident providing the upper bound on the set, inclusive",
            required: false,
        }, {
            name: "totaladc",
            type: "uint32",
            comment: "Representative total ADC of the TPs in the set.",
            required: false,
        }, {
            name: "tps",
            type: "TrigPrim",
            comment: "The trigger primitives in the set",
            repeated: true,
        }]
    }
]

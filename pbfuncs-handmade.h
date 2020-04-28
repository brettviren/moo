// This file is 100% generated, do not edit.

// Declare the functions that need to be provided by hand.

#ifndef WIRECELL_PB_FUNCS_HANDMADE
#define WIRECELL_PB_FUNCS_HANDMADE


#include "WireCellIface/ITrace.h"

#include "WireCellIface/IFrame.h"


#include "wct.pb.h"

// Converters from WCT PB to data interface.


// Access the ADC/charge waveform starting at tbin
const std::vector<float>&
wct_iface_trace_charge(const wct::pb::Trace& obj);


// Tags on the frame
const WireCell::IFrame::tag_list_t&
wct_iface_frame_frame_tags(const wct::pb::Frame& obj);

// Channel mask map
WireCell::Waveform::ChannelMaskMap
wct_iface_frame_masks(const wct::pb::Frame& obj);

// Trace indices with given tag
const WireCell::IFrame::trace_list_t&
wct_iface_frame_tagged_traces(const wct::pb::Frame& obj);

// Trace summary for given tag
const WireCell::IFrame::trace_summary_t&
wct_iface_frame_trace_summary(const wct::pb::Frame& obj);

// Union of all sets of tags on traces
const WireCell::IFrame::tag_list_t&
wct_iface_frame_trace_tags(const wct::pb::Frame& obj);

// All traces
WireCell::ITrace::shared_vector
wct_iface_frame_traces(const wct::pb::Frame& obj);



// Converters from WCT data interface to PB




// Contiguous charge measure on the channel starting at tbin.
void wct_pb_trace_charge(wct::pb::Trace& pbobj,
    const WireCell::ITrace::pointer& ifptr);
    





// Ordered collection of all traces in the frame
void wct_pb_frame_traces(wct::pb::Frame& pbobj,
    const WireCell::IFrame::pointer& ifptr);


// Array of tag strings associated with the frame
void wct_pb_frame_frame_tags(wct::pb::Frame& pbobj,
    const WireCell::IFrame::pointer& ifptr);


// Array of all tag strings associated with traces in the frame
void wct_pb_frame_trace_tags(wct::pb::Frame& pbobj,
    const WireCell::IFrame::pointer& ifptr);


// Collection of meta data info about groups of traces
void wct_pb_frame_trace_info(wct::pb::Frame& pbobj,
    const WireCell::IFrame::pointer& ifptr);


// A colelection of tagged channel masks
void wct_pb_frame_cmm(wct::pb::Frame& pbobj,
    const WireCell::IFrame::pointer& ifptr);
    
    


#endif
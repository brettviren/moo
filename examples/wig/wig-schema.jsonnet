local moo = import "moo.jsonnet";

local gs = import "graph-schema.jsonnet";
local gh = moo.oschema.hier(gs).graph;

local as = moo.oschema.schema("wct.img");

local hier = {

    // Reused scalar types

    id : gh.ID,
    index : as.number("Index", dtype='i4', doc="An index of an array"),
    wpid : as.number("WPID", dtype='i4', doc="Encoded WirePlaneID"),
    count : as.number("Count", dtype='i4', doc="A count of something"),
    position : as.number("Position", dtype='f4', doc="A position along a coordinate"),


    // Node property records

    // Edges go etween channel and wires or measurements.  Note, for
    // some detectors, the channel can be considered to be "in" the
    // wire plane of wire segment 0 and that wire should be in the
    // graph and so the WPID is not an explicit property.  Given all
    // wires, the WAN of the channel may be derived from the ordering
    // of the head point coordinates of wire segment zero.  The graph
    // is sparse so not all channels may be known and so WAN is given
    // explicitly.
    channel : as.record("Channel", [
        as.field("chid", self.id, // not node ID.
                 doc="An external identifier for this channel"),
        as.field("wan", self.index,
                 doc="Wire attachment number"),
    ], doc="Information about one channel"),

    point: as.record("Point", [
        as.field("x", self.position, doc="X positions of point"),
        as.field("y", self.position, doc="X positions of point"),
        as.field("z", self.position, doc="X positions of point"),
    ], doc="A point in 3D Cartesian space"),

    points: as.sequence("Points", self.point, doc="A sequence of points"),

    /// Properties of a wire segment
    wire: as.record("Wire", [
        as.field("wid", self.id, // not node ID
                 doc="An external identifier for the wire segment"),
        as.field("wip", self.index,
                 doc="Identify wire contiguously in its plane"),
        as.field("wpid", self.wpid,
                 doc="The wire plane ID holding the wire"),
        as.field("seg", self.count,
                 doc="The number of wire segments between this wire and the channel input"),
        as.field("tail", self.point,
                 doc="Tail point of wire segment"),
        as.field("head", self.point,
                 doc="Head point of wire segment"),
    ], doc="Information about one wire"),

    time: as.number("Time", dtype="f4", doc="A time period"),
    value: as.number("Value", dtype="f4", doc="A value, measured, estimated or uncertainty"),

    // Edges go betwee a blob, another blob (forming a cluster), a
    // slice providing the temporal bounds, wire providing the
    // physical bounds of a layer or "measurement" proficing the layers.  A blob has is
    // associated with a wire plane face via the WPID of its wires.
    blob : as.record("Blob", [
        as.field("value", self.value,
                 doc="The reconstructed charge in the blob"),
        as.field("error", self.value,
                 doc="The uncertainty in the value"),
        as.field("sliceid", self.id,
                 doc="Identity of the slice holding the blob"),
        as.field("corners", self.points,
                 doc="The points of the blob corners"),
    ], doc="Blobs localize a region of space likely containing charge"),

    sample : as.record("Sample", [
        as.field("chid", self.id,
                 doc="The channel of some activity"),
        as.field("value", self.value,
                 doc="The measured activity"),
    ], doc="A sample from a channel over a slice"),
    samples : as.sequence("Samples", self.sample,
                          doc="sequence of samples"),

    slice : as.record("Slice", [
        as.field("frameid", self.id,
                 doc="Identify the frame containing the slice"),
        as.field("start", self.time,
                 doc="The start time of the slice"),
        as.field("span", self.time,
                 doc="The time span of the slice"),
        as.field("samples", self.samples,
                 doc="The samples of activity in the slice"),
    ], doc="A slice in time"),

    // Strictly, a measurement is used only as an association of a set
    // of channels to a blob.  Thus, no properties are required.
    // However, we give a "layer" index which could be derived from
    // the wire plane index shared by all its channels.  The term
    // "measurement" here is somewhat obtuse as its value is only
    // resolved by using channels to look up samples in the slice
    // which is associated via the blob.  In principle, future schema
    // may introduce edge properties to hold a per channel weight
    // value which represents how much of the channel's sample
    // contributes to the measurement.    
    meas : as.record("Measurement", [
        as.field("layer", self.index, // technically redundant with info in channels
                 doc="The layer or wire plane of this measurement"),
    ], doc="A measurement properties"),


    // A single node type is defined which is a schema-full version of
    // std::variant held as a cluster_node_t.

    // The node types.  The "size" type is default and considered
    // illegal.
    ntype : as.enum("NodeType",
                    ["size","chan","wire","blob","slice","meas"],
                    default="size"),

    prop: as.oneOf("Property", [
        self.id,
        self.channel, self.wire, self.blob, self.slice, self.meas]),


    node : as.record("Node", [
        as.field("type", self.ntype, doc="Type of the node"),
        as.field("data", self.prop, doc="Property record"),
    ], bases=[gh.Node], doc="A WCT cluster graph node"),
    nodes: as.sequence("Nodes", self.node,
                       doc="A sequence of nodes"),
        

    graph: as.record("Graph", [
        as.field("nodes", self.nodes, doc="The nodes in the graph"),
    ], bases=[gh.Graph], doc="A WCT cluster graph"),

};

gs + moo.oschema.sort_select(hier, "wct.img")

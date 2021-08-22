/*
 * This file is 100% generated.  Any manual edits will likely be lost.
 *
 * This contains struct and other type definitions for shema in 
 * namespace wct::img.
 */
#ifndef WCT_IMG_STRUCTS_HPP
#define WCT_IMG_STRUCTS_HPP

#include <cstdint>
#include "graph/Structs.hpp"

#include <string>
#include <variant>
#include <vector>

namespace wct::img {

    // @brief A value, measured, estimated or uncertainty
    using Value = float;


    // @brief A position along a coordinate
    using Position = float;


    // @brief A point in 3D Cartesian space
    struct Point 
    {

        // @brief X positions of point
        Position x = 0.0;

        // @brief X positions of point
        Position y = 0.0;

        // @brief X positions of point
        Position z = 0.0;
    };

    // @brief A sequence of points
    using Points = std::vector<wct::img::Point>;

    // @brief Blobs localize a region of space likely containing charge
    struct Blob 
    {

        // @brief The reconstructed charge in the blob
        Value value = 0.0;

        // @brief The uncertainty in the value
        Value error = 0.0;

        // @brief Identity of the slice holding the blob
        graph::ID sliceid = 0;

        // @brief The points of the blob corners
        Points corners = {};
    };

    // @brief An index of an array
    using Index = int32_t;


    // @brief Information about one channel
    struct Channel 
    {

        // @brief An external identifier for this channel
        graph::ID chid = 0;

        // @brief Wire attachment number
        Index wan = 0;
    };

    // @brief A count of something
    using Count = int32_t;


    // @brief 
    enum class NodeType: unsigned {
        size,
        chan,
        wire,
        blob,
        slice,
        meas,
    };
    // return a string representation of a NodeType.
    inline
    const char* str(NodeType val) {
        if (val == NodeType::size) { return "size" ;}
        if (val == NodeType::chan) { return "chan" ;}
        if (val == NodeType::wire) { return "wire" ;}
        if (val == NodeType::blob) { return "blob" ;}
        if (val == NodeType::slice) { return "slice" ;}
        if (val == NodeType::meas) { return "meas" ;}
        return "";                  // should not reach
    }
    inline
    NodeType parse_NodeType(std::string val, NodeType def = NodeType::size) {
        if (val == "size") { return NodeType::size; }
        if (val == "chan") { return NodeType::chan; }
        if (val == "wire") { return NodeType::wire; }
        if (val == "blob") { return NodeType::blob; }
        if (val == "slice") { return NodeType::slice; }
        if (val == "meas") { return NodeType::meas; }
        return def;
    }

    // @brief Encoded WirePlaneID
    using WPID = int32_t;


    // @brief Information about one wire
    struct Wire 
    {

        // @brief An external identifier for the wire segment
        graph::ID wid = 0;

        // @brief Identify wire contiguously in its plane
        Index wip = 0;

        // @brief The wire plane ID holding the wire
        WPID wpid = 0;

        // @brief The number of wire segments between this wire and the channel input
        Count seg = 0;

        // @brief Tail point of wire segment
        Point tail = {};

        // @brief Head point of wire segment
        Point head = {};
    };

    // @brief A time period
    using Time = float;


    // @brief A sample from a channel over a slice
    struct Sample 
    {

        // @brief The channel of some activity
        graph::ID chid = 0;

        // @brief The measured activity
        Value value = 0.0;
    };

    // @brief sequence of samples
    using Samples = std::vector<wct::img::Sample>;

    // @brief A slice in time
    struct Slice 
    {

        // @brief Identify the frame containing the slice
        graph::ID frameid = 0;

        // @brief The start time of the slice
        Time start = 0.0;

        // @brief The time span of the slice
        Time span = 0.0;

        // @brief The samples of activity in the slice
        Samples samples = {};
    };

    // @brief A measurement properties
    struct Measurement 
    {

        // @brief The layer or wire plane of this measurement
        Index layer = 0;
    };

    // @brief 
    using Property = std::variant<graph::ID, wct::img::Channel, wct::img::Wire, wct::img::Blob, wct::img::Slice, wct::img::Measurement>;

    // @brief A WCT cluster graph node
    struct Node: public graph::Node  
    {

        // @brief Type of the node
        NodeType type = wct::img::NodeType::size;

        // @brief Property record
        Property data = {};
    };

    // @brief A sequence of nodes
    using Nodes = std::vector<wct::img::Node>;

    // @brief A WCT cluster graph
    struct Graph: public graph::Graph  
    {

        // @brief The nodes in the graph
        Nodes nodes = {};
    };

} // namespace wct::img

#endif // WCT_IMG_STRUCTS_HPP
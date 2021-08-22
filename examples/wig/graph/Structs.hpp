/*
 * This file is 100% generated.  Any manual edits will likely be lost.
 *
 * This contains struct and other type definitions for shema in 
 * namespace graph.
 */
#ifndef GRAPH_STRUCTS_HPP
#define GRAPH_STRUCTS_HPP

#include <cstdint>

#include <vector>
#include <string>

namespace graph {

    // @brief Numeric identifier
    using ID = uint64_t; // NOLINT


    // @brief Identify an instance and its type
    struct Identified 
    {

        // @brief Uniquely identify an instance
        ID id = 0;
    };

    // @brief An edge from one node to another
    struct Edge: public graph::Identified  
    {

        // @brief Identify the node from which this edge exits
        ID tail = 0;

        // @brief Identify the node from which this edge enters
        ID head = 0;
    };

    // @brief A sequence of edges
    using Edges = std::vector<graph::Edge>;

    // @brief Base node type
    struct Node: public graph::Identified  
    {
    };

    // @brief A sequence of nodes
    using Nodes = std::vector<graph::Node>;

    // @brief A graph
    struct Graph: public graph::Identified  
    {

        // @brief The nodes in the graph
        Nodes nodes = {};

        // @brief The edges in the graph
        Edges edges = {};
    };

    // @brief A sequence of graphs
    using Graphs = std::vector<graph::Graph>;

    // @brief String suitable for use as a variable/function name
    using ident = std::string;

} // namespace graph

#endif // GRAPH_STRUCTS_HPP
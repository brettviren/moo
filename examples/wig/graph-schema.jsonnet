local moo = import "moo.jsonnet";

local s = moo.oschema.schema("graph");

local hier = {
    id: s.number("ID", dtype="u8",
                 doc="Numeric identifier"),
    ident: s.string("ident", pattern=moo.schema.re.ident,
                    doc="String suitable for use as a variable/function name"),

    // At a minimum, every instance of a type needs a way for other
    // instances to refer to it.  This is done via its ID.  For the
    // reference to be unique, the ID value must be unique at least to
    // the type.
    known: s.record("Identified", [
        s.field("id", self.id,
                doc="Uniquely identify an instance"),
    ], doc="Identify an instance and its type"),

    // At its core, a graph node is merely identified.  For good
    // reason it is known as a "vertex" in graph theory.  That is, it
    // is nothing except an identified point to which other things may
    // be associated.  Application schema likely uses graph.Node as a
    // base for its own node records which add properties as
    // additional fields.
    node: s.record("Node", [
    ], bases=[self.known], doc="Base node type"),
    nodes: s.sequence("Nodes", self.node,
                      doc="A sequence of nodes"),

    // At its core, an edge is merely an associate of two nodes,
    // possibly with direction.  It must also be identified as a pair
    // of nodes may have multiple edges (multigraph).  Application
    // schema may use graph.Edge as a base record for its edge types
    // in order to provide properties.  The two nodes are
    // distinguished as tail and head if directed.  Application schema
    // wanting undirected edges may merely ignore this distinction.
    edge: s.record("Edge", [
        s.field("tail", self.id,
                doc="Identify the node from which this edge exits"),
        s.field("head", self.id,
                doc="Identify the node from which this edge enters"),
    ], bases=[self.known], doc="An edge from one node to another"),
    edges: s.sequence("Edges", self.edge, 
                      doc="A sequence of edges"),

    // At its core, a graph is merely a set of nodes and edges.  It is
    // also identified in order for a system to explicitly distinquish
    // different graphs.  An application graph type may extend
    // graph.Graph in order to associate properties.
    graph: s.record("Graph", [
        s.field("nodes", self.nodes, doc="The nodes in the graph"),
        s.field("edges", self.edges, doc="The edges in the graph"),
    ], bases=[self.known], doc="A graph"),
    graphs: s.sequence("Graphs", self.graph,
                       doc="A sequence of graphs"),
        
};

moo.oschema.sort_select(hier, "graph")


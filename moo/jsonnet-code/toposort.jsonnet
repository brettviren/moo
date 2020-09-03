// Topological sort of a directed acyclic graph.
//
// The graph, nodes and edges are kept abtract.  User must provide a
// "nodes" function to return an array of nodes given the graph and an
// "edges" function returning an array of nodes reached by edges out
// of a given node.
//
// Default nodes() and edges() assume graph is an object with keys
// representing nodes (strings) and values holding a .deps which is an
// array of other nodes to which a node shares an outgoing edge.
//
// The .toposort(graph) method returns sorted array of nodes.
//
// The algorithm is from
// https://en.wikipedia.org/wiki/Topological_sorting#Depth-first_search

function(nodes = function(graph) std.objectFields(graph),
         edges = function(graph, name) graph[name].deps)
{
    init_status(graph) :: {
        marks: {[n]:null for n in nodes(graph)},
        order: []
    },
    set_mark(status, name, m) :: status { marks: super.marks { [name]: m }},
    set_temp(status, name) :: self.set_mark(status, name, "temp"),
    set_perm(status, name) :: self.set_mark(status, name, "perm"),

    get_mark(status, name) :: if std.objectHas(status.marks, name) then status.marks[name] else null,

    set_found(status, name) :: self.set_perm(status, name) { order: super.order + [name] },

    unmarked(marks) :: std.filter(function(n) std.type(marks[n]) == "null", std.objectFields(marks)),

    visit_top(graph, status) :: {
        local um = $.unmarked(status.marks),
        res :: if std.length(um) == 0 then status else
            $.visit_top(graph, $.visit(um[0], graph, status))
    }.res,

    visit_found(name, graph, status) :: self.set_found(
        std.foldl(function(s,n) self.visit(n,graph,s), edges(graph, name),
                  self.set_temp(status, name)), name),
    visit(name, graph, status) :: {
        local mark = $.get_mark(status, name),
        assert mark != "temp",
        res: if mark == "perm" then status else $.set_found(
            std.foldl(function(s,n) $.visit(n,graph,s), edges(graph, name),
                      $.set_mark(status, name, "temp")), name),
    }.res,

    toposort(graph) ::
    self.visit_top(graph, self.init_status(graph)).order,
}

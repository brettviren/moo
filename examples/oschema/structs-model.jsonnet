// Translate a schema into a model of a set of C++ structs.
local oschema = import "oschema.jsonnet";
// Top is a function with args eg given as TLA.
// - os :: an oschema array
// - path :: select types from os which are in this path
// - lang :: a language support struct such as moo's lang/cpp.jsonnet

local basepath(p) = {
    local np = std.split(p, "."),
    res: std.join(".",np[:std.length(np)-1])
}.res;

function(os, path, lang) {
    path: oschema.listify(path),
    types: [t for t in os if oschema.isin(self.path, t.path)],
    byscn: {[tn]:[oschema.fqn(t) for t in $.types if t.schema == tn]
                   for tn in oschema.class_names},
    lang: lang,

    local extypref = std.uniq(std.sort([
        d for d in std.flattenArrays([t.deps for t in $.types]) if !oschema.isin($.path,oschema.listify(d))])),

    extpaths: std.uniq(std.sort([basepath(t) for t in extypref]))
}



// fixme: need some abstraction to handle system name to file name.
// Eg, name path to include directory path.

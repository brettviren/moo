local oschema = import "oschema.jsonnet";

function(os, path) {
    // The path/namespace this model "lives" in
    path: oschema.listify(path),
    nspre: std.join('.', self.path) + '.',

    // Select out the types "in" this namespace
    types: [t for t in os if oschema.isin(self.path, t.path)],

    // Reference full type by its FQN
    byref: {[oschema.fqn(t)]:t for t in $.types},

    // Collect types by their schema class name
    byscn: {[tn]:[oschema.fqn(t) for t in $.types if t.schema == tn]
                   for tn in oschema.class_names},
    local extypref = [
        d for d in std.flattenArrays([t.deps for t in $.types])
          if !oschema.isin($.path,oschema.listify(d))],
    extrefs: std.uniq(std.sort([oschema.basepath(t) for t in extypref]))
}

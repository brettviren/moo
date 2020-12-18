local oschema = import "oschema.jsonnet";

function(os, path, ctxpath=[]) {

    // The "path" determines which schema types in the "os" array will
    // be considered to be directly "in" the model.  The "path" may be
    // give either as a literal list of string or encoded as a
    // dot-separated string.  It is used, eg, to form a surrounding
    // C++ namespace containing the codegen'ed types.
    path: oschema.listify(path),

    // The "context path" is a prefix of the "path" to be removed when
    // refering to this model from external resources and in a
    // relative way.  Eg, the ctxpath is removed from the path when
    // forming relative #include statements between "sibling" headers
    // generated from this model.  It may either be a litteral list of
    // strings or a list of string encoded as a dot-separated string.
    ctxpath: oschema.listify(ctxpath),

    // Select out the types which are "in" the path for consideration.
    types: [t for t in os if oschema.isin(self.path, t.path)],

    // Also provide the super set of all types so that referenced
    // types may be resolved.  This super set should be complete to
    // any type referenced by a type in the "types" array above.
    all_types: os,

    // Reference any type by its FQN.
    byref: {[oschema.fqn(t)]:t for t in $.all_types},

    // Collect the types of interest by their schema class name
    byscn: {[tn]:[oschema.fqn(t) for t in $.types if t.schema == tn]
                   for tn in oschema.class_names},

    // Find external type references
    local extypref = [
        d for d in std.flattenArrays([t.deps for t in $.types])
          if !oschema.isin($.path,oschema.listify(d))],
    extrefs: std.uniq(std.sort([oschema.relpath(oschema.basepath(t), self.ctxpath) for t in extypref]))
}

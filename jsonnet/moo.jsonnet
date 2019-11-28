// This defines a schema for a very basic description of data types.
// It explicitly avoids supporting forms and concepts of different
// representations.  This schema is expected to be extended by other
// Jsonnet or Python processing.
{

    // An attr associates a type to a name in some implicit context.
    attr(type, name, comment="") :: {
        // required type identifier
        type: type,
        // name of the attribute (in some assumed context such as an object)
        name: name,
        // decribe the attribute (in a context free way)
        comment: comment,
    },

    // An aggr aggregates attributes and is itself an attr.
    aggr(name, comment, fields=[], type="struct") :: attr(type, name, comment) {
        // the fields is an array of attr and marks this as an aggr
        fields : fields,
    },

    // An aseq is a sequence of attrs of the same type.  The "type" of
    // this attribute remains that of the elements.  Existince of
    // repeated marks this as an array.
    aseq(type, name, comment="") :: attr(type,name,comment) {
        repeated: true,
    },

}

local moo = import "moo.jsonnet";

// Return a JSON Schema for type reference "typeref" (fully qualified
// name) which exists along with all other referenced types in the moo
// schema array msa.  The JSON Schema "$id" URL for this schema may be
// given in jsidurl.
//
// Example on command line:
//
// moo -A msa=examples/oschema/app.jsonnet \
//     -A typeref=app.Person \
//     compile moo2jschema.jsonnet       
//
function(typeref, msa, jsidurl="") moo.jschema.convert(msa, jsidurl)
{ "$ref": "#/definitions/"+ std.join("/",std.split(typeref,'.')) }

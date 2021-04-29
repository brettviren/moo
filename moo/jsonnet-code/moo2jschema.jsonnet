local moo = import "moo.jsonnet";

// Return a JSON Schema for type reference "typeref" (fully qualified
// name) which exists along with all other referenced types in the moo
// schema array "types".  The JSON Schema "$id" URL for this schema
// may be given in jsidurl.
//
// Example on command line:
//
// moo -A types=examples/oschema/app.jsonnet \
//     -A typeref=app.Person \
//     compile moo2jschema.jsonnet       
//
function(typeref, types, jsidurl="") moo.jschema.convert(types, jsidurl)
{ "$ref": "#/definitions/"+ std.join("/",std.split(typeref,'.')) }

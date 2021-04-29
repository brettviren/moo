local jform = import "jform.jsonnet";
local isr(x,r) = if std.type(x) != "null" then r;
// moo -M examples/oschema \
//     -A types=app.jsonnet \
//     -A typeref=app.Person \
//     compile moo2jsonform.jsonnet       
//
// May also give -A form=.... to provide the form attribute
//
function(types, typeref, form=null) jform.convert(types, typeref) {
    [isr(form,"form")]: form
}




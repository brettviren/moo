local oschema = import "oschema.jsonnet";
local jschema = import "jschema.jsonnet";
local re = import "schema/re.jsonnet";

{
    // See oschema.org for explanation.
    oschema: oschema,
    // Make JSON Schema from oschema types
    jschema: jschema,
    // Make special JSON Schema -like output for jsonform
    jform: import "jform.jsonnet",

    // A bunch of regular expressions matching common patterns.  A
    // pattern may be provided to a String schema as the "pattern"
    // attribute.
    re: re,

    // Support structure for templates.  This is provided as object
    // named "moo" in a template context.
    templ: {
    },

    // Create an object that, in an array, may be rendered with the
    // command "moo render-many".
    render(model, template, filename) :: {
        model:model, template:template, filename:filename,
    },



    // Obsolete paradigm where schema is defined through function
    // calls on an abstract schema object.
    fschema: {
        re: re,
        avro: import "schema/avro.jsonnet",
        json: import "schema/json.jsonnet",
        value: import "schema/value.jsonnet",
    },
    // keep this alias for now so existing schema doesn't break
    schema : self.fschema,
    

    // Return true if all in arr are true
    alltrue(arr) :: std.foldl(function(a,b) a && b, arr, true),
    // Return true if any in arr are true
    anytrue(arr) :: std.foldl(function(a,b) a || b, arr, false),


}

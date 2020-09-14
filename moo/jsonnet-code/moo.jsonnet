local oschema = import "oschema.jsonnet";
local re = import "schema/re.jsonnet";

{
    // See oschema.org for explanation.
    oschema: oschema,

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
    
}

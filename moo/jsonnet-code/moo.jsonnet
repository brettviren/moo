{

    // Provided domain schema for functional-schema based construction
    fschema: {
        re: import "schema/re.jsonnet",
        avro: import "schema/avro.jsonnet",
        json: import "schema/json.jsonnet",
        value: import "schema/value.jsonnet",
    },
    // keep this alias for now so existing schema doesn't break
    schema : self.fschema,

    // Support for templates.  This is provided as object named "moo"
    // in a template context.
    templ: {
    },

    // Create an object that, in an array, may be rendered with the
    // command "moo render-many".
    render(model, template, filename) :: {
        model:model, template:template, filename:filename,
    },
}

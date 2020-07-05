{
    // Aggregate built-in domain schema 
    schema: {
        re: import "schema/re.jsonnet",
        avro: import "schema/avro.jsonnet",
        json: import "schema/json.jsonnet",
        value: import "schema/value.jsonnet",
    },

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

{
    schema: {
        avro: import "schema/avro.jsonnet",
        json: import "schema/json.jsonnet",
        value: import "schema/value.jsonnet",
    },

    // Support for templates.  This is provided as object named "moo"
    // in a template context.
    templ: {
    },
}

import moo

model = "user@example.com"

json_schema = {
    "$id": "https://brettviren.github.io/moo/examples/oschema/anys.json",
    "$ref": "#/definitions/anys/OneNumOrEmail",
    "$schema": "http://json-schema.org/draft-07/schema#",
    "definitions": {
        "anys": {
            "AllNumOrEmail": {
                "allOf": [
                    {
                        "$ref": "#/definitions/anys/Count"
                    },
                    {
                        "$ref": "#/definitions/anys/Email"
                    }
                ]
            },
            "AnyNumOrEmail": {
                "allOf": [
                    {
                        "$ref": "#/definitions/anys/Count"
                    },
                    {
                        "$ref": "#/definitions/anys/Email"
                    }
                ]
            },
            "Count": {
                "maximum": 4294967295,
                "minimum": 0,
                "type": "integer"
            },
            "Email": {
                "format": "email",
                "type": "string"
            },
            "OneNumOrEmail": {
                "oneOf": [
                    {
                        "$ref": "#/definitions/anys/Count"
                    },
                    {
                        "$ref": "#/definitions/anys/Email"
                    }
                ]
            },
            "VoidStar": {}
        }
    }
}


moo.ovalid.validate(model, json_schema, throw=True)

// Utilities for testing Jsonnet

local moo = import "moo.jsonnet";

{
    // Resolve a named object in an array of named objects
    find_named(arr, name) :: std.filter(function(x) x.name == name, arr)[0],

    // Creat a validate object for a moo schema.  ID should give JSON
    // Schema "$id" URL but it's largely ignored.
    validate(moo_schema_list, ID="") :: {
        local jschema = moo.jschema.convert(moo_schema_list, ID),
        jschema: jschema, 

        mschema: {[ms.name]:ms for ms in moo_schema_list},

        // Make a unit test object from a model which corresponds to a
        // moo type.
        unit(type, model) :: {
            model: model,
            jschema: jschema {
                "$ref": '#/definitions/' + std.join('/',type.path) + '/' + type.name
            }
        },
            
        // Transpose array of schema_test to arrays of schema and model
        // If one has a top object:
        //  {
        //    fail:v.transpose_units(fails),
        //    pass:v.transpose_units(passes)
        //  }
        // then exercise like:
        // $ moo -D fail.model validate --passfail --sequence \
        //       -S fail.jschema -s top-object.jsonnet \
        //                          top-object.jsonnet 
        transpose_units(tests) :: {
            jschema: [one.jschema for one in tests],
            model: [one.model for one in tests],
        }
    }

}

// this defines schema
{
    field : {
        type: null,             // REQUIRED: data type
        name: null,             // REQUIRED: field/variable name
        comment: "",            // DEFAULT: description
        initv: null,            // OPTIONAL: initial value
        access: "public",       // DEFAULT: public/private/protected
        scalar: true,           // DEFAULT: field is scalar, not array
        optional: true,         // DEFAULT: object is whole even without field
    },

    // here, object means class/struct not instance
    object : {
        name : null,            // REQUIRED: object (class) name
        fields : [],            // DEFAULT: empty array of field
        comment : null,         // DEFAULT: no comment
        access : "public",      // DEFAULT: In C++, public is struct else class
        version: 0,             // DEFAULT: version 0.
    },

    fieldify(f) :: $.field + f,

    objectify(o) :: $.object + o + {
        fields: [$.fieldify(f) for f in o.fields],
    },
}

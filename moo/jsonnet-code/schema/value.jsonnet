// A "domain" schema for producing functions that assist in producing
// schema-valid objects.  This domain is somewhat unique in that the
// objects returned by its functions are not meant to be opaque to the
// user and instead each returned object has a .validate() method
// which may be called on a Jsonnet object of the corresponding
// "type".  The object will be returned or Jsonnet will throw an
// assert if the object is not valid.  If successful, object is passed
// through with no change.


local re = import "re.jsonnet";
local objif(key, val) = if std.type(val)=="null" then {} else {[key]:val};

{
    top(types) :: {[t.name]:t.validate for t in types},

    // return a type that validates a boolean
    boolean(name):: {
        name: name,
        validate:: function(val) {
            local jtype = std.type(val),
            assert jtype == "boolean" : 'expect boolean for "%s", got <%s>'%[name,jtype],
            ret: val,
        }.ret,
    },

    // return a type that validates a string
    string(name, pattern=null, format=null) :: {
        name: name,
        validate:: function(val) {
            local jtype = std.type(val),
            assert jtype == "string" : 'expect string for "%s", got <%s>'%[name,jtype],
            ret: val,
        }.ret,
    },
    
    // return a type that validates a number
    number(name, dtype, extra={}) :: {
        name: name,
        dtype: dtype,
        validate:: function(val) {
            local jtype = std.type(val),
            assert jtype == "number" : 'expect number for "%s", got <%s>'%[name,jtype],
            ret: val,
        }.ret,
    },

    // return a type that validates a field
    field(name, type, default=null, doc=null) :: {
        name:name,
        validate:: function(val) type.validate(val),
    },

    // Return a function that makes a record
    record(name, fields=[], doc=null) :: {
        name: name,
        validate:: function(val) {
            local jtype = std.type(val),
            assert jtype == "object" : 'expect object for "%s" record, got <%s>'%[name, jtype],
            ret: {[f.name]: f.validate(val[f.name]) for f in fields}
        }.ret,
    },

    // Return a function that makes an enum
    enum(name, symbols, default=null, doc=null) :: {
        name: name,
        validate:: function(val) {
            local got = std.setInter(std.set(symbols), std.set([val])),
            assert 1 == std.length(got) : 'illegal enum for "%s", got "%s"'%[name, val],
            ret: val
        }.ret,
    },

    sequence(name, type) :: {
        name: name,
        validate:: function(val) {
            local jtype = std.type(val),
            assert jtype == "array" : 'expect sequence for "%s", got <%s>' % [name,jtype],
            ret: [type(ele) for ele in val],
        }.ret
    },
}

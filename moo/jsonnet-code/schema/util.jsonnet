{
    // helper to return an object if with {key:val} if val is not null
    // else return empty object.  This is a workaround for building an
    // object but then applying std.prune() which can be rather slow.
    objif(key, val) :: if std.type(val)=="null" then {} else {[key]:val},

    // Return array of objects keys
    keys(obj) :: std.objectFields(obj),

    // Return array of objects values
    values(obj) :: std.map(function(x) obj[x], std.objectFields(obj)),
}

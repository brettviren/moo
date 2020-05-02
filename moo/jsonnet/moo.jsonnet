// moo Jsonnet support library

local type(key,c,p,n,d) = { name:key, c:c, p:p, n:n, j:std.type(d), def:d};
local types = [
    type("void", "void", "None", "None", null),
    type("bool", "bool", "bool", "bool", false),
    type("char", "char", "int", "int8", 0),
    type("byte", "std::byte", "bytes", "S", 0),
    type("str", "std::string", "str", "<U", "")
    ] + [
    type("int%d"%(s*8), "int%d_t"%(s*8), "int", "i%d"%s, 0)
    for s in [1,2,4,8]
    ] + [
    type("uint%d"%(s*8), "uint%d_t"%(s*8), "int", "u%d"%s, 0)
    for s in [1,2,4,8]
    ] + [
        type("int", "int", "int", "i4", 0),
        type("float", "float", "float", "f4", 0.0),
        type("double", "double", "float", "f8", 0.0),
    ];


{
    // We define some basic types.  Each type is a structure with
    // native programming language type accessed by a short letter
    // key: c:C++, p:Python, n:Numpy, j:Jsonnet, d:default Jsonnet
    // value.  The types object's keys are numpy type for fixed sized
    // numbers plus special keys: void, str, char, int, float, double
    // for unfixed types.
    types : { [t.name] : t for t in types },

    // Define an attribute as a name, a type and a default value.
    attribute :: function(name, type, adef=null) {
        name:name, type:type,
        def: if std.type(adef)=='null' && std.objectHas(type, 'def') then type.def else adef },

    // An object is a name and some attributes
    object :: function(name, attrs=[], help="") {
        name:name, attrs:attrs, help:help },

    // A method is a conduit that sends a message to an entity, eg a
    // target language object.
    method :: function(name, type=self.types.void,
                       rdef=null, attrs=[], help="") {
        name:name, type:type, def:rdef, attrs:attrs, help:help},

    // A state machine transition.  states and events are objects,
    // guards and actions are methods.
    transition :: function(ini,fin,eve=null,grds=[],acts=[],star=null) {
        ini:ini.name,
        fin:fin.name,
        eve:if std.type(eve)=='null' then null else eve.name,
        grds:[g.name for g in grds],
        acts:[a.name for a in acts],
        star:star,
    },

    // An FSM event is an object
    event :: self.object,

    // An FSM state is also an object, though usually empty.
    state :: self.object,

    // An FSM model includes a model of some context of data
    context :: self.object,

    // An FSM guard is a method returning bool
    guard :: function(name, attrs=[], help="") {
        name:name, type:$.types.bool, rdef:false,
        attrs:attrs, help:help},

    // An FSM action is a method returning nothing
    action :: function(name, attrs=[], help="") {
        name:name, type:$.types.void, rdef:null,
        attrs:attrs, help:help},

    // A state machine which may also be a state
    machine :: function(name, states, events=[], guards=[], actions=[], tt=[]) {
        name:name, states:states, events:events,
        guards:guards, actions:actions, tt:tt},

    // A command extends a method to include behavior.
    command :: function(method, machine, help="") {
        method:method, machine:machine, help:help},

    // helpers

    // return values of an object
    keys :: function(obj) std.objectFields(obj),
    values :: function(obj) std.map(function(x) obj[x], std.objectFields(obj)),


}

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
        model: "attribute",
        name:name, type:type,
        def: if std.type(adef)=='null' && std.objectHas(type, 'def') then type.def else adef },

    // An object is a name and some attributes
    object :: function(name, attrs=[], help="") {
        model: "object",
        name:name, attrs:attrs, help:help },

    // A method is a conduit that sends a message to an entity, eg a
    // target language object.
    method :: function(name, type=self.types.void,
                       rdef=null, attrs=[], help="") {
        model: "method",
        name:name, type:type, def:rdef, attrs:attrs, help:help},

    // A state machine transition.  states and events are objects,
    // guards and actions are methods.
    transition :: function(ini,fin,event=null,guards=[],actions=[],star=null) {
        model: "transition",
        ini:ini,
        fin:fin,
        event:if std.type(event)=='null' then null else event,
        guards:guards,
        actions:actions,
        star:star,
    },

    // An FSM event is an object
    event :: function(name, attrs=[], help="") self.object(name,attrs,help) {
        model: "event",
    },

    // An FSM state is also an object, though usually empty.
    state :: function(name, attrs=[], help="") self.object(name,attrs,help) {
        model: "state",
    },

    // An FSM model includes a model of some context of data
    context :: function(name, attrs=[], help="") self.object(name,attrs,help) {
        model: "context",
    },

    // An FSM guard is a method returning bool
    guard :: function(name, attrs=[], help="") {
        model:"guard",
        name:name, type:$.types.bool, rdef:false,
        attrs:attrs, help:help},

    // An FSM action is a method returning nothing
    action :: function(name, attrs=[], help="") {
        model:"action",
        name:name, type:$.types.void, rdef:null,
        attrs:attrs, help:help},

    // A state machine which may also be a state
    machine :: function(name, states, events=[], guards=[], actions=[], tt=[]) {
        model:"machine",
        name:name,
        states:states,
        events:events,
        guards:guards,
        actions:actions,
        tt:tt},

    // A command extends a method to include behavior.
    command :: function(method, machine, help="") {
        model:"command",
        method:method, machine:machine, help:help},

    // helper functions

    // Return an object built from an array of named objects.
    byname(objs) :: { [o.name]:o for o in objs },

    // return values of an object
    keys(obj):: std.objectFields(obj),
    values(obj):: std.map(function(x) obj[x], std.objectFields(obj)),


    event_things_byname(machine, thingname) ::
    [ std.split(s,":"),
      for s in std.set([ "%s:%s"%[tran.event.name,thing.name]
                         for tran in machine.tt
                         for thing in tran[thingname]])],

    // return array of unique pars of [event,thing] from machine
    event_things(machine, thingname) ::
    local es = self.byname(machine.events);
    local ts = self.byname(machine[thingname]);
    [
        [ es[ss[0]], ts[ss[1]] ] for ss in 
                                 $.event_things_byname(machine, thingname)],

    // Return array of unique pairs of [event,guard] from machine
    event_guards(machine):: self.event_things(machine, "guards"),
    // Return array of unique pairs of [event,action] from machine
    event_actions(machine):: self.event_things(machine, "actions"),

}

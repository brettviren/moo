{
    // Define a type, which is just the type name
    type :: function(typename) typename,

    // Define an attribute as a name, a type and a default value.
    attribute :: function(name, type, def=null) {
        name:name, type:type, def:def },
    
    // An object is a name and some attributes
    object :: function(name, attrs=[], help="") {
        name:name, attrs:attrs, help:help },

    // A method is a conduit that sends a message to an entity, eg a
    // target language object.
    method :: function(name, type, def=null, attrs=[], help="") {
        name:name, type:type, def:def, attrs:attrs, help:help},

    // A state machine transition.  states and events are objects,
    // guards and actions are methods.
    transition :: function(ini,fin,eve=null,grds=[],acts=[],star=null) {
        ini:ini,fin:fin,eve:eve,grds:grds,acts:acts,star:star},

    // A command extends a method to include behavior.
    command :: function(method, machine, help="") {
        method:method, machine:machine, help:help},
}

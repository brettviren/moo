local moo = import "moo.jsonnet";
local s = moo.oschema.schema("fsm");
local hier = {
    ident: s.string("Ident", pattern=moo.re.ident_only,
                    doc="An identifier or name that can be a legal variable name"),

    // Here, an FSM state is given, generally, as a dot-path.
    // Depending on the consumer (eg template), this may be
    // interpreted as a moo oschema type or as a simple string.
    state: s.string("State", pattern="^(%s)$"%moo.re.dotpath,
                    doc="An FSM state"),
    states: s.sequence("States", self.state),

    // Likewise, an event.
    event: s.string("Event", pattern="^(%s)$"%moo.re.dotpath,
                    doc="An FSM event"),
    events: s.sequence("Events", self.event),

    // An action is typically mapped to a function.
    action: s.string("Action", pattern=moo.re.ident_only,
                     doc="An FSM action"),
    actions: s.sequence("Actions", self.action),

    // Likewise a guard, but one which returns a bool.
    guard: s.string("Guard", pattern=moo.re.ident_only,
                    doc="An FSM guard"),
    guards: s.sequence("Guards", self.guard),

    // A transition describes a state change triggered by an event and
    // a number of guards that must return true and a number of
    // actions to call if they do.
    trans: s.record("Transition", [
        s.field("ini", self.state,
                doc="The initial state"),
        s.field("evt", self.event,
                doc="The triggering event"),
        s.field("fin", self.state,
                doc="The final state"),
        s.field("actions", self.actions, default=[],
                doc="Any actions"),
        s.field("guards", self.guards, default=[],
                doc="Any guards"),
    ], doc="An FSM transition"),
    transs: s.sequence("Transitions", self.trans),

    // The TT wraps it all up.  In a hiearchical FSM, a TT is also a
    // state.
    tt: s.record("TransitionTable", [
        s.field("state", self.state,
                "The state associated with the tt"),
        s.field("ini", self.state,
                doc="The initial state"),
        s.field("tt", self.transs,
                doc="The transitions"),
    ], doc="An FSM transition table"),
    tts: s.sequence("TransitionTables", self.tt),

    sm: s.record("FSMModel", [
        s.field("events", self.events),
        s.field("states", self.states),
        s.field("tts", self.tts),
        s.field("guards", self.guards),
        s.field("actions", self.actions),
    ], doc="Overall model of a FSM"),
};

moo.oschema.sort_select(hier)

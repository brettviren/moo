local moo = import "moo.jsonnet";
local echo = import "echo.jsonnet";
{
    namespace: "mex",

    // context/sml struct name.  Note: templates assume a struct
    // mex::CtxSML in to be in mex/ctxsml.hpp.
    ctxsmlname: "CtxSml",

    // protocol name: yodel + echo.  Note: templates assume a struct
    // mex::YOHO in mex/yoho.hpp.
    protoname: "YOHO",

    messages: echo.machine.events,
    context: echo.context,
    machine: echo.machine,
    event_guards: moo.event_guards(self.machine),
    event_actions: moo.event_actions(self.machine),
    test_fsm_events: [
        ["bind","initializing"],
        ["conn","initializing"],
        ["start","running"],
        ["stop","finalizing"]],

    commands: echo.commands,
}



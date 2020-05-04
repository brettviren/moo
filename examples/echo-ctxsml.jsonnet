local moo = import "moo.jsonnet";
local echo = import "echo.jsonnet";
{
    namespace: "echo",
    structname: "CtxSml",
    context: echo.proto.context,
    machine: echo.proto.machine,
    event_guards: moo.event_guards(self.machine),
    event_actions: moo.event_actions(self.machine),
    test_fsm_events: [
        ["bind","initializing"],
        ["conn","initializing"],
        ["start","running"],
        ["stop","finalizing"]],

}



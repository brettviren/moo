// The yodel protocol receives a song with a reverb count.  If reverb
// count is breater than zero, the song is sent with the count
// decremented by one.

local moo = import "moo.jsonnet";
local trans = moo.transition;

local messages = [
    moo.message("song",
                [moo.attribute("notes", moo.types.str),
                 moo.attribute("reverb", moo.types.int)]),
];


local defaults = {
    namespace: "mex",
    protoname: "yodel",
};


local peer_tt = [
    trans(moo.state('idle'), moo.state('running'), moo.event("play"),
          actions=[moo.action('notify_app')], star="*"),
    trans(moo.state('running'), moo.state('idle'), moo.event("pause"),
          actions=[moo.action('notify_app')])
] + [
    trans(moo.state('running'), moo.state('running'), moo.event(eve),
          guards=[moo.guard('is_audible')],
          actions=[moo.action('do_echo')])
    for eve in [m.name for m in messages]];

{

    // codec for protocol messages
    codec: defaults {
        classname: "YodelCodec",
        messages: moo.identify(messages),
        fields : moo.fields(self.messages),
    },

    // A protocol handler models a state machine with an associated
    // data object shared by guards, events and the handler owner.
    // Receiving a protocol message sharing a name with an event will
    // lead to that event being injected to the SM by the handler.  We
    // assume the codec is available to the guards and actions and so
    // no message information is included in events.    
    handlers : {
        // Yodel may be handled in a symmetric manner.  Other
        // protocols might have separate "client" or "server" protocol
        // handlers.  Here, we just have one.
        peer : defaults + {
            classname: "YodelPeer",
            codec: $.codec,
            // the protocol messages we know about (possible subset,
            // but here, all)
            messages: messages,
            machine: moo.machine("yodelpeer", peer_tt),
        },
    }
}

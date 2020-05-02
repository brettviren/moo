// this models the echo protocol.
local moo = import "moo.jsonnet";
local trans = moo.transition;

local states = {
    ini: moo.object("initalizing"),
    run: moo.object("running"),
    fin: moo.object("finalizing"),
};
local events = {
    // events from commands
    start: moo.object("start", help="Begin running"),

    bind: moo.object("bind", [ moo.attribute("address", moo.types.str) ],
                     "Bind external socket to address"),
    conn: moo.object("conn", [ moo.attribute("address", moo.types.str) ],
                     "Connect external socket to address"),
    stop: moo.object("stop", help="Cease running"),
    yodel: moo.object("yodel", [ moo.attribute("song", moo.types.str) ],
                      "Sing a song to the universe"),
    echo:  moo.object("echo", [
        moo.attribute("shout", moo.types.str),
        moo.attribute("deadline", moo.types.int, 1000),
    ], "Shout and wait for an answer"),

    // events from the universe
    hear: moo.object("hear", [moo.attribute("song", moo.types.str)],
                     "Receive a song from a distance"),
};
local act = {
    bind: moo.action("do_bind"),
    conn: moo.action("do_conn"),
    unlink: moo.action("do_unlink"),
    send: moo.action("do_send"),
    recv: moo.action("do_recv"),
};

{
    proto: {

        context: moo.object("context", [moo.attribute("status", moo.types.str)],
                            "The protocol context object"),

        machine: moo.machine("echo",
                             moo.values(states),
                             moo.values(events),
                             actions=moo.values(act),
                             tt = [
            trans(states.ini, states.ini, events.bind, acts=[act.bind], star="*"),
            trans(states.ini, states.ini, events.conn, acts=[act.conn]),
            trans(states.ini, states.run, events.start),
            trans(states.run, states.run, events.yodel, acts=[act.send]),
            trans(states.run, states.run, events.echo,
                  acts=[act.send,act.recv]),
            trans(states.run, states.run, events.hear, acts=[act.recv]),
            trans(states.ini, states.fin, events. stop, acts=[act.unlink]),
            trans(states.run, states.fin, events. stop, acts=[act.unlink]),
        ]),
    }
}

local f = import "fsm-makers.jsonnet";

local states = {
    rdy: "Ready",
    ini: "Initialized",
    cfg: "Configured",
    run: "Running",
};

local events = {
    init: "evInit",
    conf: "evConf",
    start: "evStart",
    stop:  "evStop",
    scrap:  "evScrap",
    fini:  "evFini",
};

local trans = [
    {ini:states.rdy, evt:events.init, fin:states.ini},
    {ini:states.ini, evt:events.conf, fin:states.cfg},
    {ini:states.cfg, evt:events.start, fin:states.run},
    {ini:states.run, evt:events.stop, fin:states.cfg},
    {ini:states.cfg, evt:events.scrap, fin:states.ini},
    {ini:states.ini, evt:events.fini, fin:states.rdy},
];

local tt = {
    state:"Life",
    ini: states.rdy,
    tt: trans
};

{
    events: events,
    states: states,
    tts: [tt],
    guards: [],
    actions: [],
}
            

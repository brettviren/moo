local moo = import "moo.jsonnet";
local lang = import "moo/cpp.jsonnet";
local string = lang.types.string;
local boolean = lang.types.boolean;
// events
local start = moo.object("start", [moo.attribute("greeting", string, '""')]);
local quit = moo.object("quit");
// states
local ini = moo.object("initializing");
local wrk = moo.object("working");
local fin = moo.object("finalizing");
// guards
local awake = moo.method("check_awake", boolean, false);
local happy = moo.method("check_happy", boolean, false);
// actions
local dowork = moo.method("dig_that_hole", lang.types.notype);
// transition table
local tt = [
    moo.transition(ini,wrk,start,[awake,happy],[dowork]),
    moo.transition(wrk,fin,quit)
];
local ctx = moo.object("gear", [ moo.attribute("lunch", string, '"sandwich"'),
                                 moo.attribute("tool", string, '"hammer"') ]);
local worksm = moo.object("work", [ moo.attribute("tt", tt),
                                    moo.attribute("context", ctx) ]);
worksm

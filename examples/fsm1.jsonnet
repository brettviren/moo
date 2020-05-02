local moo = import "moo.jsonnet";
// events
local start = moo.event("start", [ moo.attribute("greeting", moo.types.str)]);
local quit = moo.event("quit");
// states
local ini = moo.state("initializing");
local wrk = moo.state("working");
local fin = moo.state("finalizing");
// guards
local awake = moo.guard("check_awake");
local happy = moo.guard("check_happy");
// actions
local dowork = moo.action("dig_that_hole");
// transition table
local tt = [
    moo.transition(ini,wrk,start,[awake,happy],[dowork]),
    moo.transition(wrk,fin,quit)
];
local ctx = moo.object("gear", [
    moo.attribute("lunch", moo.types.str, '"sandwich"'),
    moo.attribute("tool", moo.types.str, '"hammer"') ]);
local worksm = moo.machine("work", tt, ctx);
worksm

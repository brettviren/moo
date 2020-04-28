// the waf wscript knows what to do with this file.

local podtype = function(c,j) {c:c,j:j};
local string = podtype("std::string", "string");
local int = podtype("int", "number");
local bool = podtype("bool", "boolean");
local void = podtype("void", "null");

local attr = function(name, type, def) { name:name, type:type, def:def };
local message = function(name, attrs=[]) { name:name, attrs:attrs};
local errval = function(key, value, code) {key:key,value:value,code:code};

local accept = function(key, msg, errors=[]) {
    key:key, message:msg, errors:errors
};
local command = function(help, message, type, default, accepts) {
    help:help, message:message, type:type, default:default, accepts:accepts
};

local machine_eve_grds = function(machines) [
    std.split(s,":") for s in  std.set(["%s:%s"%[t.eve.name,g] for m in machines for t in m.tt for g in t.grds]) ];

local machine_eve_acts = function(machines) [
    std.split(s,":") for s in  std.set(["%s:%s"%[t.eve.name,a] for m in machines for t in m.tt for a in t.acts])];

local machine_events = function(machines) 
std.set([t.eve for m in machines for t in m.tt], function(e) e.name);

// An event is a message
local event = message;
local sm = function(name, tt=[], type="sm") { type:type, name:name, tt:tt };
local state = function(name) sm(name, type="state");
local trans = function(ini, fin, eve="", grds=[], acts=[], star="") {
    ini:ini, fin:fin, eve:eve, grds:grds,acts:acts,star:star};
// A guard or an action are just names. 

// describe an error that throws runtime exception
local runtime = function(name) errval("error", "true", 'throw std::runtime_error("%s failed");'%name);


// model a protocol endpoint

local messages = {
    conn: message("connect", [ attr("endpoint",string, '""') ]),
    bind: message("bind", [ attr("port",int, "-1") ]),
    yodel: message("yodel", [ attr("song", string, '""') ]),
    echo: message("echo", [ attr("song", string, '""') ]),

    status: message("status", [ attr("ok", bool, "false") ]),
    port_reply: message("status", [ attr("port", int, "-1") ]),
};
local events = {
    start: event("start", [attr("greeting", string, '""')]),
    done: event("done"),
};


// some commands are likely used by many protocols
local commands = {
    connect: command("Connect protocol socket to the given endpoint",
                     messages.conn,  bool, "false",
                     [ accept("ok", messages.status, [ runtime("connect") ])]),
    bind:command("Bind protocol socket to the given port number, return it",
                 messages.bind, int, "-1",
                 [ accept("port", messages.port_reply, [
                     runtime("bind") ])]),
    
};

{
    license: |||
          This is a generated file and not intended to be modified.
          It and the model from which it was generated may be distributed
          under the LGPLv3 license.  See COPYING for details.
        |||,

    description: "This API is for testing the moo code generator.",

    namespace: "foo",

    endpoints: {
        // We could model multiple endpoitns, such as one for server
        // and one for clint.  The example echo is symmetric so we
        // have only one.
        echo : {
            api: {
                classname: 'EchoAPI',
                description: 'Classic example of hello world hello world hello world....',
            },
            proto: {
                classname: 'EchoProto',
                description: 'Protocol endpoint handler for echo protocol'
            },

            machines: [ sm("jigger", [
                trans("start","waiting",events.start,
                      ["is_nice", "is_capital"],
                      ["print_event", "print_event"], "*"),
                trans("start","done",events.start,
                      ["is_mean", "is_capital"], ["print_event"]),
                trans("start","done",events.done, acts=["print_event"])])],

            // fixme:need to bundle a set of all eves and states
            eve_grds: machine_eve_grds(self.machines),
            eve_acts: machine_eve_acts(self.machines),
            events: machine_events(self.machines),

            methods: [
                commands.connect,
                commands.bind,

                command("Send a message to the other end, wait to hear something back",
                        messages.echo, string, '""',
                        [ accept("song", messages.echo, [
                            runtime("echo") ])]),

                command("Send a message to the other end",
                        messages.yodel, bool, "false",
                        [ accept("ok", messages.status, [
                            runtime("yodel") ])]),
            ]
        }                       // echo
    }                           // apis
}                               // model

    

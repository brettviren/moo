local moo = import "moo.jsonnet";

local mks = function(regex) {type:"string", pattern: regex};


{
    tcp: {
        valid: moo.re.tcp,
        good: "tcp://127.0.0.1:1234",
        bad: "xyz://127.0.0.1:1234",
    }
}

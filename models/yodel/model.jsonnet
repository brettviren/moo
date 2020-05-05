// The yodel protocol receives a song with a reverb count.  If reverb
// count is breater than zero, the song is sent with the count
// decremented by one.

local moo = import "moo.jsonnet";
{
    protoname: "yodel",
    messages: moo.identify([
        moo.event("song",
                  [moo.attribute("notes", moo.types.str),
                   moo.attribute("reverb", moo.types.int)]),
    ]),
}

// access schema primitive functions
local moc = import "moc.jsonnet";
{
    schema(s):: {
        hint: s.enum("Hint", ["JSON","BSON","CBOR","UBJS","MSGP",
                              "JSNT","AVRJ","AVRB","PBUF"]),
    },

    base: self.schema(moc.base).hint,
    avro: self.schema(moc.avro).hint,
    jscm: self.schema(moc.jscm).hint,
    tmpl: {
        namespace: "moc",
        types: [ $.avro ],
    },

    data: "JSON",

}

local moc = import "moc.jsonnet";

{
    schema(s) :: {
        local name = s.string(pattern='^[a-zA-Z ]$'),
        local address = s.string(pattern='^[a-zA-Z0-9 ]$'),
        local age = s.number("i4", {minimum:0}),
        local person = s.record("Person", [
            s.field("name", name),
            s.field("address", address),
            s.field("age", age)
        ]),
        ret: person,
    }.ret,

    base: self.schema(moc.base),
    avro: self.schema(moc.avro),
    jscm: self.schema(moc.jscm),


}

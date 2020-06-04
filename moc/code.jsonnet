local moo = import "moo.jsonnet";
local moc = import "schema.jsonnet";
local mt = moc.types;

{
    schema: {},
    
    model: {
        components: [
            
        ]

        apps: [
            mt.application(
                "app1",
                components = [
                    mt.demo.source("ts1", 10, ["src1"]),
                ],
                portset = [
                    mt.port("src1", "push", mt.connect_auto("app2","snk1"))
                ])
        ]
    }
    

}

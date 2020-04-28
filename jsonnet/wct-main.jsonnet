local wct = import "wct.jsonnet";

[
    {
        template: "pbiface.cpp.j2",
        artifact: "pbiface.cpp",
        params: wct,
    },
    
]

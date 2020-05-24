local moo = import "moo.jsonnet";
local ms = moo.schema;
ms.schema(
    ms.object(
        {
            name:ms.string(),
            url:ms.string(format="uri")
        },
        required=["name", "url"]
    )
)

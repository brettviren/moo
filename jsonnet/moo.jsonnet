{
    schema : {
        string(format=null, id=null) ::
        std.prune({type:"string",format:format,"$id":id}),

        number(id=null) :: std.prune({ type:"number", "$id":id}),

        numeric(dtype,id=null) ::
        std.prune(self.object({value:$.schema.number(),
                               dtype:dtype, "$id":id})),

        integer(id=null) :: self.numeric("i4", id),

        array(items=null,id=null) ::
        std.prune({type:"array", items:items, "$id":id}),

        object(properties, required=[], id=null) ::
        std.prune({type:"object", required:required,
                   properties:properties,"$id":id}),

        enum(lst=[],id=null) ::
        std.prune({ type:"string", enum:lst, "$id":id }),

        allOf(lst,id=null) :: std.prune({"allOf": lst, "$id": id}),
        anyOf(lst,id=null) :: std.prune({"anyOf": lst, "$id": id}),
        oneOf(lst,id=null) :: std.prune({"oneOf": lst, "$id": id}),

        ref(id) :: {"$ref": "#/definitions/"+id },

        schema(body={}, definitions={}, id=null, version="draft-07") ::
        std.prune({
            "$schema": "http://json-schema.org/%s/schema#"%version,
            "$id": id,
            definitions:definitions}) + body,
    },
    
    types : {
        numeric(value, dtype) :: {value:value, dtype:dtype},
        integer(value) :: $.types.numeric(value, 'i4'),
    }    
}

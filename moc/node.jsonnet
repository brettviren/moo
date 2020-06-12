// moc node related schema
local moc = import "moc.jsonnet";
local re = import "re.jsonnet";
{
    schema(s) :: {
        local ident = s.string(pattern=re.ident_only),
        local address = s.string(pattern=re.uri),

        local ltype = s.enum("LinkType", ["bind","connect"], default="bind",
                             doc="How a port links to an address"),
        local link = s.record("Link", fields= [
            s.field("linktype", "LinkType",
                    doc="The socket may bind or connect the link"),
            
            s.field("address", address, 
                    doc="The address to link to")
        ], doc="Describes how a single link is to be made"),
        local port = s.record("Port", fields=[
            s.field("ident", ident,
                    doc="Identify the port uniquely in th enode"),
            s.field("links", s.sequence("Link"), 
                    doc="Describe how this port should link to addresses"),
        ], doc="A port configuration object",),
        local comp = s.record("Comp", fields=[
            s.field("ident", ident, 
                    doc="Identify copmponent instance uniquely in the node"),
            s.field("type_name", ident, 
                    doc="Identify the component implementation"),
            s.field("portlist", s.sequence(ident), 
                    doc="Identity of ports required by component"),
            s.field("config", s.string(), 
                    doc="Per instance configuration string used by node")
        ], doc="An object used by the node to partly configure a component"),
        local node = s.record("Node", fields=[
            s.field("ident", ident,
                    doc="Idenfity the node instance"),
            s.field("portdefs", s.sequence("Port"), 
                    doc="Define ports on the node to be used by components"),
            s.field("compdefs", s.sequence("Comp"),
                    doc="Define components the node should instantiate and configure"),
        ], doc="A node configures ports and components"),

        types: [ ltype, link, port, comp, node ],
    },


    // Base schema is just a simple JSON dump
    base: self.schema(moc.base).types,

    // Directly generate Avro schema which is json
    avro: self.schema(moc.avro).types,

    // Schema to generate nlohmann::json
    nljs: {   
        // Template is written to take Avro schema for types
        types:$.avro,
        // Fixme: this value here represents a semantic sheer.
        namespace:"moc",
        // Fixme: this value here represents a semantic sheer.
        name: "node",
    },

    // Schema to validate calibration objects.
    jscm: self.schema(moc.jscm).types,

}

// ECMA / JSON Schema regular expressions matching various things
{
    // Basic identifier (restrict to legal C variable nam)
    ident: '[a-zA-Z][a-zA-Z0-9_]*',
    ident_only: '^' + self.ident + '$',
    // DNS hostname
    dnslabel: '([a-zA-Z0-9][a-zA-Z0-9\\-]*[^-])+',
    dnshost: '(\\*)|(%s(\\.%s)*)' % [self.dnslabel, self.dnslabel],
    // URIs are either of the zeromq type:
    // - tcp://host:port
    tcpport: '(:(\\*)|([0-9]+))?',
    tcp: '^tcp://' + self.dnshost + self.tcpport + '$',
    hiername: '[^/\\| ]+',
    hierpath: '/?(%s/?)+' % self.hiername,
    // - ipc://filename.ipc
    ipc: '^ipc://' + self.hierpath + '$',
    // - inproc://label
    inproc: '$inproc://' + self.hiername + '$',

    // or for auto connect via Zyre discovery
    // - zyre://nodename/portname[?header=value]
    //
    // Node names are not (necessarily) hostnames and may be liberally
    //defined as anything not looking like a URI delim.
    //nodename: '[^#:/\\?]+',
    nodename: '[^/]+',
    // Likewise port names
    portname: '[^/]+',
    // we'll let zyre also match on arbitrary headers
    param: '(\\?%s=%s(&%s=%s)*)?' % [self.ident for n in std.range(0,3)],
    zyre: '^zyre://%s/%s%s$' % [self.nodename, self.portname, self.param],

    // All supported URI (no http/https yet)
    uri: std.join('|', [self.tcp, self.ipc, self.inproc, self.zyre]),

    // match an instance name for a component
    compname: self.ident,
    // match a "typename" for a component
    comptype: self.ident,
}    

// ECMA / JSON Schema regular expressions matching various things
{
    // Basic identifier (restrict to legal C variable nam)
    ident: '[a-zA-Z][a-zA-Z0-9_]*',
    ident_only: '^' + self.ident + '$',
    // DNS hostname
    ipv4: '[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}',
    dnslabel: '[a-zA-Z0-9]([a-zA-Z0-9\\-]*[a-zA-Z0-9])?',
    dnshost: '%s(\\.%s)*' % [self.dnslabel, self.dnslabel],

    tcpport: '(:[0-9]+)?',

    // a slash-separated list/path like FS paths
    // fixme: this is maybe too accepting
    hiername: '[^/\\| ]+',
    hierpath: '/?(%s/?)+' % self.hiername,
    // a dot-separated list/path list Python modules
    dotname: self.ident,
    dotpath: '%s(\\.%s)*' % [self.dotname, self.dotname],

    // thing specific to zmq
    zmq: {
        tcp: {
            // add zeromq wild card
            host: '(\\*)|(%s)' % $.dnshost,
            // URIs are either of the zeromq type:
            // with zeromq wild card
            port: '(:(\\*|[0-9]+))?',
            // zeromq tcp scheme
            uri: 'tcp://(%s|%s)(%s)' % [self.host, $.ipv4, self.port],
        },
        ipc: {
            uri: 'ipc://' + $.hierpath,
        },
        inproc: {
            uri: 'inproc://' + $.hiername,
        },

        uri_list : [self.tcp.uri, self.ipc.uri, self.inproc.uri],
        uri: '(%s)' % std.join('|',['(%s)'%one for one in self.uri_list]),
        
        socket: {
            name_list: [
                "PAIR", "PUB", "SUB", "REQ", "REP", "DEALER", "ROUTER",
                "PULL", "PUSH", "XPUB", "XSUB", "STREAM", "SERVER", "CLIENT",
                "RADIO", "DISH", "GATHER", "SCATTER", "DGRAM", "PEER",
            ],
            name: std.join('|',['(%s)'% one for one in self.name_list]),
        },
    },

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


    // match an instance name for a component
    compname: self.ident,
    // match a "typename" for a component
    comptype: self.ident,
}    

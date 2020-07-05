local moo = import "moo.jsonnet";
local re = moo.schema.re;

function(schema) {

    local ident = schema.string(pattern=re.ident_only),

    local osversion = schema.enum(
        "OSVersion",
        ["CentOS7","CentOS8"], default="CentOS7",
        doc="Operating system verison of the host"),
    
    local queuetype = schema.enum(
        "QueueType",
        ["FollySPSCQueue","FollyMPMCQueue","StdDeQueue"], 
    	default="FollySPSCQueue",
        doc="Type of queue interconnecting DAQ modules."),

    local queue = schema.record("Queue", fields= [
    	schema.field("ident", ident, doc="queue name"),
	schema.field("capacity", schema.number(dtype="i4"), 2,
                     doc="Number of entries the queue can hold"),
	schema.field("kind", queuetype,
                     doc="The specific queue implementation to use"),
    ], doc = "Describes a queue connecting DAQ modules"),
    local queuelist = schema.sequence("Queue", queue),

    local modulepath = schema.string("ModulePath",
                                     pattern=re.hierpath),
    local daqmodule = schema.record("DAQModule", fields = [
    	schema.field("ident", ident, doc="DAQ module name"),
	schema.field("modulePath", modulepath,
                     doc="path where to find the shared lib corresponding to the module"),
    ], doc = "Describes a generic DAQ module"),
    local daqmodlist = schema.sequence("DAQModList", daqmodule),
    
    local host = schema.record("Host", fields= [
    	schema.field("ident", ident,
                doc="The host name"),
        schema.field("osversion", osversion,
                     doc="The OS running on the host")], 
	doc="Binds a OS version to a host"),
    
    local executable = schema.record("Executable", fields=[
    	  schema.field("ident", ident, 
	  	   doc="executable name"),
          ], doc="Describes the executable for a process."),

    local application = schema.record("Application", fields=[
    	schema.field("ident", ident, doc="application name"),
        schema.field("executable", executable,
                     doc = "Executable to use for this application"),
	schema.field("runsOn", host, doc = "Where to run the application"),
    ], doc="General configuration for an application"),
    local applist = schema.sequence("AppList", application),

    local controller = schema.record("Controller", fields=[
        schema.field("application", application,
                     doc="Controllers application config"),
        schema.field("children", applist,
                     doc="Configurations for child processes to control"),
    ], doc = "Describes a controller application"),

    local dfapplication = schema.record("DFApplication", fields=[
        schema.field("application", application,
                     doc="Controllers application config"),
	schema.field("queues", queuelist,
                     doc="Queues used in the application"),
        schema.field("modules", daqmodlist,
                     doc="DAQ modules used in the application"),
    ], doc = "Describes a dataflow application"),

    types: [ ident, osversion, queuetype, queue, queuelist,
             modulepath, daqmodule, 
             host, executable, application, applist,
             controller, dfapplication ],
}

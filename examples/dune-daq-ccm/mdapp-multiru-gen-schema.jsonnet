// Schema describing the minidaqapp.mdapp_multiru_gen CLI options.

local moo = import "moo.jsonnet";
local ns = "minidaqapp.mdapp_multiru_gen";
local as = moo.oschema.schema(ns);
local nc = moo.oschema.numeric_constraints;

local hier = {
    int: as.number("Int", 'i4', nc(multipleOf=1.0)),
    float: as.number("Float", 'f4', nc(multipleOf=1.0)),
    flag: as.boolean("Flag", doc="If True, flag should be enabled"),
    path: as.string("Path", pattern=moo.re.hiername),
    host: as.string("Host", pattern='(%s|%s)' % [moo.re.dnshost, moo.re.ipv4]),
    hosts: as.sequence("Hosts", self.host),
    argpath: as.string("ArgbPath", pattern=moo.re.hiername,
                       doc="A path provided as an argument instead of an option"),

    main: as.record("MdappMultiruGen", [
        as.field("number_of_data_producers", self.int, default=2,
                 doc="Number of links to use, either per ru (<10) or total. If total is given, will be adjusted to the closest multiple of the number of rus"),
        as.field("emulator_mode", self.flag),
        as.field("data_rate_slowdown_factor", self.float, default=1),
        as.field("run_number", self.int, default=333),
        as.field("trigger_rate_hz", self.float, default=1.0),
        as.field("token_count", self.int, default=10),
        as.field("data_file", self.path, default='./frames.bin'),
        as.field("output_path", self.path, default='.'),
        as.field("enable_trace", self.flag),
        as.field("use_felix", self.flag),
        as.field("host_df", self.host, default='localhost'),
        as.field("host_ru", self.hosts,
                 doc="This option is repeatable, with each repetition adding an additional ru process."),
        as.field("host_trigger", self.host, default='localhost'),
        as.field("host_hsi", self.host, default='localhost'),
        as.field("hsi_event_period", self.float, default=1e9),
        as.field("hsi_device_id", self.int, default=0),
        as.field("mean_hsi_signal_multiplicity", self.float, default=1),
        as.field("hsi_signal_emulation_mode", self.int, default=0),
        // Kurt has default as bits: 0b00000001.  We could require a
        // string with pattern matching 0x, 0o, 0b, or number.  For
        // now do easiest thing.
        as.field("enabled_hsi_signals", self.int, default=1),
        as.field("enable_raw_recording", self.flag),
        as.field("raw_recording_output_dir", self.path, default='.'),
        as.field("json_dir", self.argpath),
    ], doc="The CLI for minidaqapp.mdapp_multiru_gen module"),
};
moo.oschema.sort_select(hier, ns)

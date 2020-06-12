/** demo moc as an application using high-level config stream
 */

#include "demo_config.hpp"
#include "demo_config_nljs.hpp"

#include "moc/stream.hpp"
#include "moc/util.hpp"

#include <fstream>

int main(int argc, char* argv[])
{
    std::string streamname = "/dev/stdin";
    if (argc > 1) {
        streamname = argv[1];
    }
    std::string streamtype = "";
    if (argc > 2) {
        streamtype = argv[2];
    }
    std::ifstream fstr(streamname);
    // fixme: add zeromq or other network stream examples

    moc::type_stream ts = moc::make_type_stream(fstr, streamtype);

    auto nodecfg = ts.pop<moc::Node>();
    std::cout << "Config for moc::Node ID: \"" << nodecfg.ident << "\"\n";

    // Iterate through our configuration.  In this demo we will
    // "configure" by simply printint out the configuration.

    // In a real app we'd create port objects (sockets) 
    for (const auto& portcfg : nodecfg.portdefs) {
        std::cout << "\tnode port ID: \"" << portcfg.ident << "\"\n";

        for (const auto& linkcfg : portcfg.links) {
            std::cout << "\t\tlink type:" << as_int(linkcfg.linktype)
                      << " address:\"" << linkcfg.address << "\"\n";
        }
    }

    // In a real app we'd get component instances by their type and
    // instance names from a factory in the form of some IConfigurable
    // interface.
    for (const auto& compcfg : nodecfg.compdefs) {
        std::cout << "\tnode comp type \"" << compcfg.type_name << "\""
                  << " instance \"" << compcfg.ident << "\""
                  << " wants port IDs:";
        for (const auto& pn : compcfg.portlist) {
            std::cout << " \"" << pn << "\"";
        }
        // This is some instance specific config string which probably
        // should be deleted from the concept.  The idea is that it
        // would be ENCODED configuration object.  But the new idea is
        // what comes next.
        std::cout << "\n\t\tinstance config: \"" << compcfg.config << "\"\n";
    }

    return 0;
}

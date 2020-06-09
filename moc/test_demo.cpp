#include "demo_config.hpp"
#include "demo_config_nljs.hpp"

// fixme: goal is to make this in a plugin
#include "demo_app.hpp"
#include "demo_app_nljs.hpp"

#include "json.hpp"

#include <iostream>
#include <fstream>

using json = nlohmann::json;

template <typename Enumeration>
auto as_int(Enumeration const value)
    -> typename std::underlying_type<Enumeration>::type
{
    return static_cast<typename std::underlying_type<Enumeration>::type>(value);
}

int main(int argc, char* argv[])
{
    assert(argc>1);

    // fixme: future we need this istream to be returned via factory
    // method based on argv values so we may switch between, eg,
    // delivering via local file and socket.
    std::ifstream cfgstream(argv[1]);

    // fixme: here we expose the nature of the representation used in
    // the "transport" of the configuration information.  We'd like to
    // hide that to allow different representations to be dynamically
    // selected.  The mechanism of that needs to be templated/typed.
    json jobj;
    cfgstream >> jobj;
    auto nodecfg = jobj.get<moc::Node>();

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

    // We now get the component instance configuration as the next
    // object in the config stream.  As with nodecfg we seek to
    // hide the use of json types in future versions.
    //
    // Something like:
    //
    // icomp = factory.get(compcfg.type_name, compcfg.ident);
    // icomp->configure(cfgstream);
    while (true) {
        json jobj;
        try {
            cfgstream >> jobj;
        }
        catch (json::parse_error& pe) {
            if (pe.id == 101) {
                break;
            }
            throw ;
        }
        std::cout << "\t\tinstance config:\n" << jobj << "\n";
    }
    return 0;
}

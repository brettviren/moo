#include "demo_nljs.hpp"
#include "node_nljs.hpp"

#include "moc/stream.hpp"
#include "moc/util.hpp"

#include <map>
#include <fstream>

struct Interface {
    virtual ~Interface() {};
};

// Mock up of a configurable component interface.
struct IConfigurable : virtual public Interface {
    virtual ~IConfigurable() {}
    virtual void configure(const std::string& name, moc::type_stream& ts) = 0;
};

// In a real app like based on ZIO::node, ports are useful objects and
// a portset_t would be a map from port name to port object.  Here we
// just use a dummy that maps names to itself.
using portset_t = std::map<std::string, std::string>;

// Mock up a configurable component which takes ports
struct IPorted : virtual public Interface {
    virtual ~IPorted() {}
    virtual void set_ports(const portset_t& ports) = 0;
};

template<typename IType>
IType& fake_factory(std::string impname, std::string instname);

struct Node : public IConfigurable {

    ~Node() {}

    void configure(const std::string& name, moc::type_stream& ts) {

        auto cfg = ts.pop<moc::Node>();
        std::cout << "Config for moc::Node ID: \"" << cfg.ident << "\"\n";

        for (const auto& portcfg : cfg.portdefs) {
            std::cout << "\tnode port ID: \"" << portcfg.ident << "\"\n";

            for (const auto& linkcfg : portcfg.links) {
                 std::cout << "\t\tlink type:" << as_int(linkcfg.linktype)
                           << " address:\"" << linkcfg.address << "\"\n";
             }
         }

         for (const auto& compcfg : cfg.compdefs) {
             std::cout << "\tnode comp type \"" << compcfg.type_name << "\""
                       << " instance \"" << compcfg.ident << "\""
                       << " wants port IDs:";
             portset_t ps;

             for (const auto& pn : compcfg.portlist) {
                 std::cout << " \"" << pn << "\"";
                 ps[pn] = pn;    // mock
             }
             std::cout << "\n\t\tinstance config: \"" << compcfg.config << "\"\n";
            
             // demo:lookup
             auto& ip = fake_factory<IPorted>(compcfg.type_name, compcfg.ident);
             ip.set_ports(ps);
         }
     }
};

// Mock up of a component.  In a real app this implementation would be
// provided by a plugin shared library.
class SourceComponent : public IConfigurable, public IPorted {
public:
    virtual ~SourceComponent() {};
    void configure(const std::string& n, moc::type_stream& ts) {
        name = n;
        auto mycfg = ts.pop<moc::Source>();
        std::cout << "SourceComponent " << name << " configuring\n";
        std::cout << "\tntosend = " << mycfg.ntosend << "\n";
    }

    void set_ports(const portset_t& ports) {
        std::cout << "Source " << name << " using ports:";
        for (auto& pp : ports) {
            std::cout << " " << pp.first;
        }
        std::cout << "\n";
    }
private:
    std::string name;
};

using instmap_t = std::map<std::string, Interface*>;
static std::map<std::string, instmap_t> have;

// This is a mock up of a dlopen/dlsym based plugin/factory
template<typename IType>
IType& fake_factory(std::string impname, std::string instname)
{

    // In a "real" factory method each implementation would register a
    // creational function with an "implementation name" to the
    // factory and what interfaces it implements.  Here, we hard wire
    // the factory pattern.  Note, the "implementation name" need (and
    // does) not match the C++ class name.
    if (! (impname == "MySource" or impname == "Node")) {
        throw std::runtime_error("No such implementation: " + impname);
    }        

    std::cout << "Factory: " << impname << " instance " << instname << "\n";

    Interface* iptr = have[impname][instname]; // create new entries okay
    if (iptr) {
        std::cout << "Have " << impname << " instance " << instname << "\n";        
    }
    else {
        if (impname == "Node") {
            std::cout << "Creating new Node\n";
            iptr = new Node;
        }
        if (impname == "MySource") {
            std::cout << "Creating new SourceComponent\n";
            iptr = new SourceComponent;
        }
        assert(iptr);           // this must not assert
        have[impname][instname] = iptr;
    }

    IType* ptr = dynamic_cast<IType*>(iptr);
    if (!ptr)  {
        throw std::runtime_error("Not of type: " + impname);
    }

    return *ptr;
}
        


// Here we moc a configuration manager that knows about IConfigurable
// and which sets a moc message stream schema.  That is, it requires
// honoring a contract on the order and content of messages.  It
// assumes messages come in pairs: [imp,inst][config]
void do_configure(moc::type_stream& ts)
{
    while (true) {
        moc::ConfigHeader ch;
        try {
            ch = ts.pop<moc::ConfigHeader>();
        }
        catch (std::runtime_error(re)) {
            // fixme: mock: find a less dramatic way to signal end of stream
            std::cout << "configure done\n";
            return;
        }

        auto& ic = fake_factory<IConfigurable>(ch.impname, ch.instname);
        ic.configure(ch.instname, ts);
    }
}

int main(int argc, char* argv[])
{
    if (argc == 1) {
std::cerr << "Must provide at least a configuation file.\n";
        return -1;
    }

    // In a real framework, we'd construct the stream via factory to,
    // for example, allow user code to not care if configuration
    // stream comes from a file or message passing.
    std::string streamname = "/dev/stdin";
    if (argc > 1) {
        std::string maybe = argv[1];
        if (maybe == "-") { maybe = streamname; }
        streamname = maybe;
    }
    std::string streamtype = "json";
    if (argc > 2) {
        streamtype = argv[2];
    }

    // demo:main
    std::ifstream fstr(streamname);
    moc::type_stream ts = moc::make_type_stream(fstr, streamtype);
    do_configure(ts);

    return 0;
}

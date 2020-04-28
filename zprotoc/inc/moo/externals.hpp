#ifndef MOO_EXTERNALS_HPP_SEEN
#define MOO_EXTERNALS_HPP_SEEN

#include "zmq.hpp"
#include "json.hpp"

namespace moo {
    using json = nlohmann::json;
    using namespace zmq;
}

#endif

#ifndef MOO_APP_HPP_SEEN
#define MOO_APP_HPP_SEEN

#include <vector>
#include <string>

namespace moo {

    using remote_identity_t = std::string;

    class app {
      public:

        /// Base class constructor should create central SM, sockets,
        /// PHs, PCs.

        virtual ~app() {}

        /// Return names of supported protocols.
        virtual std::vector<std::string> protocols() = 0;

        /// The app runs when called
        virtual void operator()() = 0;


    };
}

#endif

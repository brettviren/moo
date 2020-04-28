#ifndef MOO_PROTOBASE_HPP_SEEN
#define MOO_PROTOBASE_HPP_SEEN

#include "moo/externals.hpp"

namespace moo {

    class protobase {
      public:

        // socket handlers
        virtual void handle_command(socket_t& sock) = 0;
        virtual void handle_message(socket_t& sock) = 0;
        virtual void handle_protocol(socket_t& sock) = 0;
    };
}

#endif

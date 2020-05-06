/**
 * A moo::handler provides a base class for handling protocol
 * messages.
 *
 * The subclass likely has access a codec.
 *
 * The subclass is likely an FSM.
 */

#ifndef MOO_HANDLER_HPP_SEEN
#define MOO_HANDLER_HPP_SEEN

#include "zmq.hpp"

namespace moo {

    class handler {
      public:
        
        virtual ~handler() {}

        /// Receive notification that a codec is ready for processing.
        virtual void notice() = 0;

    };
}

#endif

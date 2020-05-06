#ifndef MOO_HANDLER_HPP_SEEN
#define MOO_HANDLER_HPP_SEEN

#include "zmq.hpp"

namespace moo {

    class handler {
      public:
        
        virtual ~handler();

        // The handler call, subclass implements
        virtual void operator()(zmq::event_flags flags) = 0;

    };
}

#endif

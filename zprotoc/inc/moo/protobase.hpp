/** moo::protobase - base class for protocol handlers
 *
 */
#ifndef MOO_PROTOBASE_HPP_SEEN
#define MOO_PROTOBASE_HPP_SEEN

#include "moo/externals.hpp"

namespace moo {

    /** base class for all protocol handlers
     *
     * This class is mostly not user-servicable.  It is intended to be
     * subclassed by a generated class declaration with inline methods
     * specified in the model or with user-provided implementations.
     */
    class protobase {
      public:

        virtual ~protobase();

        // Quasi-internal method called from actor thread.
        void run(moo::socket_t& cmdsock, moo::socket_t& msgsock);

      protected:

        // For subclass override.  Will be called once from run.
        virtual void init(){};

        // Subclass must implement this to handle any activity on the
        // actor command link. 
        virtual void handle_command(socket_t& cmdsock) = 0;

        // Subclass must implement this to handle any activity on the
        // actor message link.
        virtual void handle_message(socket_t& msgsock) = 0;

      protected:

        // Subclass may add additional protocol sockets and handlers.
        active_poller_t m_poller;
        
    };
}

#endif

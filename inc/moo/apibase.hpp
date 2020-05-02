#ifndef MOO_APIBASE_HPP_SEEN
#define MOO_APIBASE_HPP_SEEN

#include "moo/externals.hpp"

#include <vector>
#include <thread>

namespace moo {

    // moo/protobase.hpp
    class protobase;

    class apibase {
      public:

        virtual ~apibase();

        socket_t& command_link() { return m_cmdsock; }
        socket_t& message_link() { return m_msgsock; }

        // Serialize a json object to a message
        message_t to_message(const json& obj);
        // Deserialize a message to a json
        json to_object(const message_t& msg);

        // Send a command to the command pipe
        void send_command(const json& obj);
        // Receive a result from the command pipe
        json recv_result();
        
      protected:

        // Subclass must call with its protocol implementation which
        // will be given to the actor.  It must not create any
        // non-thread-safe sockets in its constructor.  
        apibase(std::unique_ptr<protobase> proto);

      private:
        context_t m_ctx;
        // sockets make this class not copiable
        socket_t m_cmdsock, m_msgsock;
        std::thread m_actor;
    };
    
} // moo

#endif // MOO_APIBASE_HPP_SEEN

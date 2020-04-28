#ifndef MOO_APIBASE_HPP_SEEN
#define MOO_APIBASE_HPP_SEEN

#include "moo/externals.hpp"

#include <vector>

namespace moo {

    // moo/protobase.hpp
    class protobase;

    class apibase {
      public:

        // Serialize a json object to a message
        message_t to_message(const json& obj);
        // Deserialize a message to a json
        json to_object(const message_t& msg);

        // Send a command to the command pipe
        void send_command(const json& obj);
        // Receive a result from the command pipe
        json recv_result();
        
      protected:

        // Subclass must call with its protocol implementation.
        apibase(std::unique_ptr<protobase> proto);

      private:
        std::unique_ptr<protobase> m_proto;
        socket_t m_cmdpipe, m_msgpipe;
    };
    
} // moo

#endif // MOO_APIBASE_HPP_SEEN

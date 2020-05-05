#ifndef MOO_CODEC_HPP_SEEN
#define MOO_CODEC_HPP_SEEN

#include "zmq.hpp"
#include "json.hpp"
#include <string>

namespace moo {
    using json = nlohmann::json;

    /// One included low-level codec is MessagePack
    json zmp2json(const zmq::message_t& msg);
    zmq::message_t json2zmp(const json& j);

    class codec {
      public:

        /// The name of the protocol for which it may handle messages
        virtual std::string proto_name() const = 0;

        /// Receive a message from the isock and populate associated fields
        virtual void recv(zmq::socket_t& sock);

        /// Set fields and ident based on contents of message
        virtual void set(const zmq::message_t& msg) = 0;

        /// Send a message based on current ident and associated fields
        virtual void send(zmq::socket_t& sock);

        /// Get message contents based on ident and fields
        virtual void get(zmq::message_t& msg) = 0;

        /// Return the current message identity.  Semantic meaning of
        /// ident numbers are codec-specific but must be non-negative.
        virtual int get_ident() const { return m_ident; }

        /// Set the current message identity
        virtual void set_ident(int id) { m_ident = id; }

        /// subclass shall provide set/get for individual fields:
        /// fieldtype get_field();
        /// and
        /// void set_field(fieldtype val);

        /// subclass shall provide set/get for events/messages:
        /// MessageType get_messagetype();
        /// and
        /// void set_messagetype(const MessageType& msg);

        /// Called once after construction.
        virtual void init() {};

      protected:
        // current message ident
        int m_ident{-1};
    };
}
#endif

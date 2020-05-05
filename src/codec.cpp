#include "moo/codec.hpp"

moo::json moo::zmp2json(const zmq::message_t& msg)
{
    const std::uint8_t* data = msg.data<std::uint8_t>();
    const size_t size = msg.size();
    const std::vector<std::uint8_t> vdat(data,data+size);
    return moo::json::from_msgpack(vdat);
}

zmq::message_t moo::json2zmp(const moo::json& j)
{
    const std::vector<std::uint8_t> v8 = moo::json::to_msgpack(j);
    return zmq::message_t(v8.data(), v8.size());
}



void moo::codec::recv(zmq::socket_t& sock)
{
    zmq::message_t msg;
    auto res = sock.recv(msg, zmq::recv_flags::none);
    res.reset();                // avoid unused warning
    this->set(msg);
}
    
void moo::codec::send(zmq::socket_t& sock)
{
    zmq::message_t msg;
    this->get(msg);
    auto res = sock.send(msg, zmq::send_flags::none);
    res.reset();                // avoid unused warning
}
        

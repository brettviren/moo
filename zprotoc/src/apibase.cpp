#include "moo/apibase.hpp"


moo::message_t moo::apibase::to_message(const json& obj)
{
    std::vector<std::uint8_t> dat = json::to_msgpack(obj);
    return moo::message_t(dat.data(), dat.size());
}
moo::json moo::apibase::to_object(const moo::message_t& msg)
{
    const std::uint8_t* data = msg.data<std::uint8_t>();
    const size_t size = msg.size();
    const std::vector<std::uint8_t> vdat(data,data+size);
    return json::from_msgpack(vdat);    
}
void moo::apibase::send_command(const json& obj) {
    auto msg = to_message(obj);
    auto res = m_cmdpipe.send(msg, moo::send_flags::none);
    if (!res) {
        throw std::runtime_error("blocking socket send timeout");
    }
}
moo::json moo::apibase::recv_result() {
    moo::message_t msg;
    auto res = m_cmdpipe.recv(msg, moo::recv_flags::none);
    if (!res) {
        throw std::runtime_error("blocking socket recv timeout");
    }
    return to_object(msg);
}
        

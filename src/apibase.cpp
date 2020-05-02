#include "moo/apibase.hpp"
#include "moo/protobase.hpp"

using namespace moo;


static
std::pair<socket_t, socket_t> create_linked_pairs(context_t& ctx,
                                                  std::string name="link")
{
    std::pair<socket_t, socket_t> ret{
        socket_t(ctx, socket_type::pair),
        socket_t(ctx, socket_type::pair)};
    std::stringstream ss;
    ss << "inproc://" << name
       << "-" << std::hex << ret.first.handle() << "-"
       << ret.second.handle();
    std::string addr = ss.str();
    ret.first.bind(addr.c_str());
    ret.second.connect(addr.c_str());
    return ret;
}

apibase::apibase(std::unique_ptr<protobase> proto)
    : m_ctx{}
{
    socket_t  cmdsock, msgsock;
    std::tie(cmdsock, m_cmdsock) = create_linked_pairs(m_ctx,"command");
    std::tie(msgsock, m_msgsock) = create_linked_pairs(m_ctx,"message");

    m_actor = std::thread(
        [proto = std::move(proto)](socket_t cmd, socket_t msg) {
            proto->run(cmd, msg);
            cmd.send(message_t{}, send_flags::none);
        },
        std::move(cmdsock), std::move(msgsock));
}


message_t apibase::to_message(const json& obj)
{
    std::vector<std::uint8_t> dat = json::to_msgpack(obj);
    return message_t(dat.data(), dat.size());
}
json apibase::to_object(const message_t& msg)
{
    const std::uint8_t* data = msg.data<std::uint8_t>();
    const size_t size = msg.size();
    const std::vector<std::uint8_t> vdat(data,data+size);
    return json::from_msgpack(vdat);    
}
void apibase::send_command(const json& obj) {
    auto msg = to_message(obj);
    auto res = m_cmdsock.send(msg, send_flags::none);
    if (!res) {
        throw std::runtime_error("blocking socket send timeout");
    }
}
json apibase::recv_result() {
    message_t msg;
    auto res = m_cmdsock.recv(msg, recv_flags::none);
    if (!res) {
        throw std::runtime_error("blocking socket recv timeout");
    }
    return to_object(msg);
}
        

#include "moo/protobase.hpp"

#include <chrono>

using namespace moo;

protobase::~protobase()
{
}

void protobase::run(socket_t& cmdsock, socket_t& msgsock)
{
    m_poller.add(cmdsock, event_flags::pollin,
                 [this, &cmdsock](event_flags){
                     this->handle_command(cmdsock);
                 });
    m_poller.add(msgsock, event_flags::pollin,
                 [this, &msgsock](event_flags){
                     this->handle_message(msgsock);
                 });
    this->init();
}


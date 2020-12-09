#ifndef NETWORKQUEUE_MSGPACK_JSON_HPP_
#define NETWORKQUEUE_MSGPACK_JSON_HPP_

#include <nlohmann/json.hpp>
#include <msgpack.hpp>

// This is an ugly hack to allow objects of moo schema type "any" to
// be serialized by MsgPack: "any" objects are represented in C++ by
// nlohmann::json objects, so we need a way to serialize
// nlohmann::json to MsgPack. We do that by dumping the nlohmann::json
// object to a json string and MsgPack-serializing the string. So we
// have two layers of serialization, which is inelegant, but it works
namespace msgpack {
MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS) {
namespace adaptor {

template<>
struct convert<nlohmann::json> {
    msgpack::object const& operator()(msgpack::object const& o, nlohmann::json& v) const {
        if (o.type != msgpack::type::ARRAY) throw msgpack::type_error();
        if (o.via.array.size != 1) throw msgpack::type_error();
        v=nlohmann::json::parse(o.via.array.ptr[0].as<std::string>());
        return o;
    }
};

template<>
struct pack<nlohmann::json> {
    template <typename Stream>
    packer<Stream>& operator()(msgpack::packer<Stream>& o, nlohmann::json const& v) const {
        // packing member variables as an array.
        o.pack_array(1);
        o.pack(v.dump());
        return o;
    }
};

}
}
}

#endif // include guard

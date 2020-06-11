#ifndef MOC_UTIL_HPP
#define MOC_UTIL_HPP

namespace moc {

    template <typename Enumeration>
    auto as_int(Enumeration const value)
        -> typename std::underlying_type<Enumeration>::type {
        return static_cast<typename std::underlying_type<Enumeration>::type>(value);
    }

}


#endif

#include "app/JsonCpp.hpp"

#include <sstream>

std::string jstr=R"({ "make": "Datsun", "model": "b210", "type": "fun"})";

int main()
{
    std::stringstream ss(jstr);
    Json::Value obj;
    ss >> obj;


    return 0;
}

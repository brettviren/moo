#!/bin/bash

# q and d, totally unportable build

set -e
set -x

./moo.py jsonnet/wct-main.jsonnet

protoc wct.proto --cpp_out=.

g++ \
    -I$HOME/dev/wct/iface/inc \
    -I$HOME/dev/wct/util/inc  \
    -I/usr/include/jsoncpp \
    -I/usr/include/eigen3 \
    -I. \
    -o pbfuncs.o \
    -c pbfuncs.cpp  

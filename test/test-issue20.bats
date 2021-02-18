#!/usr/bin/env bats

@test "compile schema" {
    run moo compile $BATS_TEST_DIRNAME/issue20-schema.jsonnet
}

@test "generate and compile codegen" {
    tmpdir=$(mktemp -d /tmp/moo-issue20.XXXXX)
    echo "$tmpdir"
    run moo -M $BATS_TEST_DIRNAME \
        -g '/lang:ocpp.jsonnet' \
        -A path=test \
        -A ctxpath=test \
        -A os=issue20-schema.jsonnet  \
        render -o $tmpdir/junk.hpp omodel.jsonnet ostructs.hpp.j2 
    echo "$output"
    [ "$status" -eq 0 ]
    [ -s $tmpdir/junk.hpp ]

    cat <<EOF > $tmpdir/junk.cpp
#include "junk.hpp"
int main()
{
    return 0;
}
EOF
    run g++ -std=c++17 -o $tmpdir/junk $tmpdir/junk.cpp
    echo "$output"
    [ "$status" -eq 0 ]
    [ -s $tmpdir/junk ]
    [ -x $tmpdir/junk ]

    rm -rf "$tmpdir"
}

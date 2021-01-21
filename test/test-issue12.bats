#!/usr/bin/env bats

@test "compile schema with enum" {
    run moo -M $BATS_TEST_DIRNAME compile issue12.jsonnet
}

@test "render schema with enum" {
    run moo -M $BATS_TEST_DIRNAME \
        -g '/lang:ocpp.jsonnet' \
        -A os=issue12.jsonnet \
        -A path=issue12 \
        render omodel.jsonnet ostructs.hpp.j2
    echo "$output"
    [ -n "$(echo -e "$output" | grep 'include <string>')" ]
}


#!/usr/bin/env bats

@test "test issue #2" {
    run moo -g '/lang:ocpp.jsonnet' \
            -A os=test/issue2.jsonnet \
            -A path=dunedaq.readout.datalinkhandler \
            render omodel.jsonnet ostructs.hpp.j2
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$(echo -e "$output" | grep 'using trfa = bool')" ]
}

@test "test issue #2 with MOO_LOAD_PATH" {
    export MOO_LOAD_PATH=$BATS_TEST_DIRNAME
    run moo -g '/lang:ocpp.jsonnet' \
            -A os=issue2.jsonnet \
            -A path=dunedaq.readout.datalinkhandler \
            render omodel.jsonnet ostructs.hpp.j2
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$(echo -e "$output" | grep 'using trfa = bool')" ]
}

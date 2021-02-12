#!/usr/bin/env bats

@test "jsonnet returns high precision" {
    run jsonnet $BATS_TEST_DIRNAME/issue11.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ "$output" != "0.8" ]
}

@test "moo compile hides lost precision" {
    run moo compile $BATS_TEST_DIRNAME/issue11.jsonnet    
    echo "$output"
    [ "$status" -eq 0 ]
    [ "$output" == "0.8" ]
}


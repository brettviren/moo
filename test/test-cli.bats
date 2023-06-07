#!/usr/bin/env bats

@test "resolve moo.jsonnet" {
    run moo resolve moo.jsonnet
    echo "$output"
    [[ $status -eq 0 ]]

    [[ -n "$(echo $output | grep moo/jsonnet-code/moo.jsonnet)" ]]
}

@test "find paths to that may contain moo.jsonnet" {
    run moo path moo.jsonnet
    echo "$output"
    [[ $status -eq 0 ]]

    [[ -n "$(echo $output | grep moo/jsonnet-code)" ]]
}



@test "moo knows own moo.jsonnet" {
    run moo compile moo.jsonnet
    echo "$output"
    [[ $status -eq 0 ]]
}

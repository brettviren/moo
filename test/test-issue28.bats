#!/usr/bin/env bats

@test "okay with existing" {
    run moo -M /tmp version
    echo "$output"
    [ "$status" -eq 0 ]
    [ -z "$( echo -e "$output" | grep Usage)" ]
}

@test "okay with missing" {
    run moo -M /does/not/exist version
    echo "$output"
    [ "$status" -eq 0 ]
    [ -z "$( echo -e "$output" | grep Usage)" ]
    [ -n "$( echo -e "$output" | grep 'path does not exist: /does/not/exist')" ]
}

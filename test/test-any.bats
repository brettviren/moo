#!/usr/bin/env bats

@test "test any" {
    run moo -M test -D model validate  -S valid -s test/test-any.jsonnet test/test-any.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ "$output" = 'null' ]
}

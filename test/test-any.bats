#!/usr/bin/env bats

@test "test any" {
    run moo -M test -D model validate  -S valid -s test/test-any.jsonnet test/test-any.jsonnet
    [ "$output" = 'null' ]
}

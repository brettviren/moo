#!/usr/bin/env bats

@test "test any" {
    local res=$(moo -M test validate \
                    -s context:test/test-any.jsonnet \
                    -t targets:test/test-any.jsonnet \
                    models:test/test-any.jsonnet)

    [ "$(echo -e "$res" | grep -c true)" -eq 2 ]
    [ "$(echo -e "$res" | grep -c false)" -eq 0 ]
}

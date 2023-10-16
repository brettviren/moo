#!/usr/bin/env bats

@test "match simple regex match" {
    run moo regex '^[a-z]$' a
    [[ "$status" -eq 0 ]]
    echo "$output"
    [[ -n $(echo "$output" | grep "OKAY:") ]]
}

@test "match simple regex miss" {
    run moo regex '^[a-z]$' aa
    [[ "$status" -ne 0 ]]
    echo "$output"
    [[ -z $(echo "$output" | grep "OKAY:") ]]
}

@test "match rpath regex match" {
    run moo regex -R zmq.tcp.uri schema/re.jsonnet 'tcp://127.0.0.1:1234'
    [[ "$status" -eq 0 ]]
    echo "$output"
    [[ -n $(echo "$output" | grep "OKAY:") ]]
}

@test "match rpath regex miss" {
    run moo regex -R zmq.tcp.uri schema/re.jsonnet 'inproc://endpoint'
    [[ "$status" -ne 0 ]]
    echo "$output"
    [[ -z $(echo "$output" | grep "OKAY:") ]]
}

#!/usr/bin/env bats

@test "find jinja import via template path in moo imports" {
    run moo -T test/issue29 imports test/issue29-template.txt.j2
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [[ $output =~ issue29/issue29-macros.j2 ]]
}

@test "find jinja import via template path in moo render" {
    run moo -T test/issue29 render "" test/issue29-template.txt.j2
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [[ $output =~ "hello world" ]]
}

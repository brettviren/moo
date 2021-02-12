#!/usr/bin/env bats

@test "compile with default TLA" {
    run moo -M test compile issue8.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ "$(echo "$output"| jq .val)" = "10" ]
    [ "$(echo "$output"| jq .typ)" = '"number"' ]
}

do_one() {
    var="$1" ; shift
    typ="$1" ; shift
    val="${1:-$var}" 
    run moo -M test -A var="$var" compile issue8.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ "$(echo "$output"| jq .val)" = "$val" ]
    [ "$(echo "$output"| jq .typ)" = "\"$typ\"" ]
}

@test "compile with TLA from CLI with int" {
    do_one 10 number
}
@test "compile with TLA from CLI with float" {
    do_one 6.9 number
}
@test "compile with TLA from CLI with bool" {
    do_one yes boolean true
}
@test "compile with TLA from CLI with string" {
    do_one "hello world" string '"hello world"'
}
@test "compile with TLA from CLI with file" {
    run moo -M test -A var=issue8.jsonnet compile issue8.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ "$(echo "$output"| jq .typ)" = '"object"' ]    
    [ "$(echo "$output"| jq .val.typ)" = '"number"' ]    
    [ "$(echo "$output"| jq .val.val)" = "10" ]    
}

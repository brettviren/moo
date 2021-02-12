#!/usr/bin/env bats

@test "template paths" {
    run moo path ocpp.hpp.j2
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ "$(echo -e "$output" | wc -l)" -eq 1 ]
}

@test "template paths user" {
    run moo -T $BATS_TEST_DIRNAME path ocpp.hpp.j2
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ "$(echo -e "$output" | wc -l)" -eq 2 ]
}

@test "model paths" {
    run moo path jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ "$(echo -e "$output" | wc -l)" -eq 1 ]
}

@test "model paths user" {
    run moo -M $BATS_TEST_DIRNAME path jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ "$(echo -e "$output" | wc -l)" -eq 2 ]
}

@test "resolve builtin template" {

    run moo resolve ocpp.hpp.j2
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ -n "$(echo "$output" | grep 'templates/ocpp.hpp.j2')" ]

}

@test "resolve builtin template with extra path" {
    run moo -T /tmp resolve ocpp.hpp.j2
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ -n "$(echo "$output" | grep 'templates/ocpp.hpp.j2')" ]
}    

@test "imports find builtin template" {
    run moo -T $BATS_TEST_DIRNAME/issue18/templates imports mytmpl.hpp.j2
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ -n "$(echo "$output" | grep 'templates/ocpp.hpp.j2')" ]
}

@test "render template from user path" {
    run moo -M $BATS_TEST_DIRNAME -T $BATS_TEST_DIRNAME/issue18/templates render issue18-model.jsonnet mytmpl-noimport.hpp.j2
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "render template from user path which imports builtin" {
    run moo -M $BATS_TEST_DIRNAME -T $BATS_TEST_DIRNAME/issue18/templates render issue18-model.jsonnet mytmpl.hpp.j2
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ -n "$(echo "$output" | grep 'A_B_ISSUE18_HPP')" ]
}

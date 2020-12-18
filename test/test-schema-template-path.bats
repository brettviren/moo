#!/usr/bin/env bats

@test "compile t-s-t-p test input" {
    run moo compile test/test-schema-template-path.jsonnet
}

function extract_namespace {
    grep '^namespace' | awk '{print $2}'
}

# test ostruct

@test "render ostructs on all-in-one model" {
    res=$(moo -D model render test/test-schema-template-path.jsonnet ostructs.hpp.j2)
    [ "$(echo -e "$res" | extract_namespace)" = "test::schema::template::path" ]
    [ -n "$(echo -e "$res" | grep 'using Email')" ]
    [ -n "$(echo -e "$res" | grep 'using Whatever')" ]
    [ -n "$(echo -e "$res" | grep 'using Count')" ]
    [ -n "$(echo -e "$res" | grep 'struct Thing')" ]
}
@test "render ostructs on model1" {
    res=$(moo -D model1 render test/test-schema-template-path.jsonnet ostructs.hpp.j2)
    [ "$(echo -e "$res" | extract_namespace)" = "test::schema::template::path::schema1" ]
    [ -n "$(echo -e "$res" | grep 'using Email')" ]
    [ -n "$(echo -e "$res" | grep 'using Whatever')" ]
    [ -z "$(echo -e "$res" | grep 'using Count')" ]
    [ -z "$(echo -e "$res" | grep 'struct Thing')" ]
}
@test "render ostructs on model2" {
    res=$(moo -D model2 render test/test-schema-template-path.jsonnet ostructs.hpp.j2)
    [ "$(echo -e "$res" | extract_namespace)" = "test::schema::template::path::schema2" ]
    [ -z "$(echo -e "$res" | grep 'using Email')" ]
    [ -z "$(echo -e "$res" | grep 'using Whatever')" ]
    [ -n "$(echo -e "$res" | grep 'using Count')" ]
    [ -n "$(echo -e "$res" | grep 'struct Thing')" ]
}

## test onljs
 
@test "render onljs on all-in-one model" {
    res=$(moo -D model render test/test-schema-template-path.jsonnet onljs.hpp.j2)
    [ "$(echo -e "$res" | extract_namespace)" = "test::schema::template::path" ]
}
@test "render onljs on model1" {
    res=$(moo -D model1 render test/test-schema-template-path.jsonnet onljs.hpp.j2)
    [ "$(echo -e "$res" | extract_namespace)" = "test::schema::template::path::schema1" ]
    [ -z "$(echo -e "$res" | grep '_json')" ]

}
@test "render onljs on model2" {
    res=$(moo -D model2 render test/test-schema-template-path.jsonnet onljs.hpp.j2)
    [ "$(echo -e "$res" | extract_namespace)" = "test::schema::template::path::schema2" ]
    [ "$(echo -e "$res" | egrep '_json.*Thing' | wc -l)" = "2" ]
}

## test omsgp

@test "render omsgp on all-in-one model" {
    res=$(moo -D model render test/test-schema-template-path.jsonnet omsgp.hpp.j2)
    [ -n "$(echo -e "$res" | grep convert | grep Whatever)" ]
    [ -n "$(echo -e "$res" | grep convert | grep Thing)" ]
}
@test "render omsgp on model1" {
    res=$(moo -D model1 render test/test-schema-template-path.jsonnet omsgp.hpp.j2)
    [ -n "$(echo -e "$res" | grep convert | grep Whatever)" ]
    [ -z "$(echo -e "$res" | grep convert | grep Thing)" ]

}
@test "render omsgp on model2" {
    res=$(moo -D model2 render test/test-schema-template-path.jsonnet omsgp.hpp.j2)
    [ -z "$(echo -e "$res" | grep convert | grep Whatever)" ]
    [ -n "$(echo -e "$res" | grep convert | grep Thing)" ]
}

#!/usr/bin/env bats

@test "trivial test" {
    echo "hi";
}

@test "compile oschema/sys example" {
    run moo compile examples/oschema/sys.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq '.[0].schema')" = '"number"' ]
}

@test "compile oschema/app example" {
    run moo compile examples/oschema/app.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq '.[0].schema')" = '"number"' ]
}
@test "simple TLAs" {
    run moo -A arg="hi" compile examples/oschema/tla.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "TLA as a file" {
    run moo -A arg=examples/oschema/sys.jsonnet compile examples/oschema/tla.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "TLAs as in Jsonnet code" {
    run moo compile examples/oschema/tla-sys.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "moo dump" {
    run moo -M examples/oschema -t moo.oschema.typify dump -f pretty app.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "moo simple render" {
    run moo -T examples/oschema -M examples/oschema \
        -t 'moo.oschema.typify|moo.oschema.graph|moo.oschema.depsort' \
        render app.jsonnet ool.txt.j2
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "another TLA compile test" {
    run moo -M examples/oschema \
        -A os='app.jsonnet' -A path='app' \
        compile omodel.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "moo transform feature" {
    run moo -M examples/oschema \
        -A os='app.jsonnet' -A path='app' \
        -t '/types:moo.oschema.typify|moo.oschema.graph|moo.oschema.depsort' \
        dump -f pretty omodel.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "moo graft feature with render" {
    run moo -g '/lang:ocpp.jsonnet' \
        -M examples/oschema \
        -A os='app.jsonnet' -A path='app' \
        render omodel.jsonnet ostructs.hpp.j2
    echo "$output"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "multi element path and omodel" {
    run moo -M examples/oschema -A os='app.jsonnet' -A path='a.b.app' -A ctxpath='a.b' compile omodel.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
}

## removed old style validate.  See test-issue17.bats for new style exercised.
# @test "moo validate anys" {
#     res=$(moo -D fail.model validate --passfail --sequence \
#               -S fail.valid -s examples/oschema/anys-data.jsonnet examples/oschema/anys-data.jsonnet)
#     [ "$?" -eq 0 ]
#     [ -z "$(echo $res | grep PASS)" ]
#     res=$(moo -D pass.model validate --passfail --sequence \
#               -S pass.valid -s examples/oschema/anys-data.jsonnet examples/oschema/anys-data.jsonnet)
#     [ "$?" -eq 0 ]
#     [ -z "$(echo $res | grep FAIL)" ]
# }

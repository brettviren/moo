#!/usr/bin/env bats

@test "trivial test" {
    echo "hi";
}

@test "compile oschema/sys example" {
    run moo compile examples/oschema/sys.jsonnet
    [ "$(echo "$output" | jq '.[0].schema')" = '"number"' ]
}

@test "compile oschema/app example" {
    run moo compile examples/oschema/app.jsonnet
    [ "$(echo "$output" | jq '.[0].schema')" = '"number"' ]
}
@test "simple TLAs" {
    run moo -A arg="hi" compile examples/oschema/tla.jsonnet
    [ -n "$output" ]
}

@test "TLA as a file" {
    run moo -A arg=examples/oschema/sys.jsonnet compile examples/oschema/tla.jsonnet
    [ -n "$output" ]
}

@test "TLAs as in Jsonnet code" {
    run moo compile examples/oschema/tla-sys.jsonnet
    [ -n "$output" ]
}

@test "moo dump" {
    run moo -M examples/oschema -t moo.oschema.typify dump -f pretty app.jsonnet
    [ -n "$output" ]
}

@test "moo simple render" {
    run moo -T examples/oschema -M examples/oschema \
        -t 'moo.oschema.typify|moo.oschema.graph|moo.oschema.depsort' \
        render app.jsonnet ool.txt.j2
    [ -n "$output" ]
}

@test "another TLA compile test" {
    run moo -M examples/oschema \
        -A os='app.jsonnet' -A path='app' \
        compile omodel.jsonnet
    [ -n "$output" ]
}

@test "moo transform feature" {
    run moo -M examples/oschema \
        -A os='app.jsonnet' -A path='app' \
        -t '/types:moo.oschema.typify|moo.oschema.graph|moo.oschema.depsort' \
        dump -f pretty omodel.jsonnet
    [ -n "$output" ]
}

@test "moo graft feature with render" {
    run moo -g '/lang:ocpp.jsonnet' \
        -M examples/oschema \
        -A os='app.jsonnet' -A path='app' \
        render omodel.jsonnet ostructs.hpp.j2
    [ -n "$output" ]
}

@test "multi element path and omodel" {
    res=$(moo -M examples/oschema -A os='app.jsonnet' -A path='a.b.app' -A ctxpath='a.b' compile omodel.jsonnet)
    [ "$(echo $res | jq '.nspre')" = '"a.b.app."' ]
    [ "$(echo $res | jq '.ctxpre')" = '"a.b."' ]
    [ "$(echo $res | jq '.relpath')" = '"app"' ]
}

@test "moo validate anys" {
    res=$(moo -D fail.model validate --passfail --sequence \
              -S fail.valid -s examples/oschema/anys-data.jsonnet examples/oschema/anys-data.jsonnet)
    [ -z "$(echo $res | grep PASS)" ]
    res=$(moo -D pass.model validate --passfail --sequence \
              -S pass.valid -s examples/oschema/anys-data.jsonnet examples/oschema/anys-data.jsonnet)
    [ -z "$(echo $res | grep FAIL)" ]
}

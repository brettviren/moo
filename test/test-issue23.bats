#!/usr/bin/env bats

@test "compile to non-existent" {
    tmpdir=$(mktemp -d /tmp/issue23.XXXXX)
    tgt="$tmpdir/compile/does/not/exist/moo.json"
    run moo compile -o "$tgt" moo.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ -s "$tgt" ]
    rm -rf $tmpdir
}
@test "imports to non-existent" {
    tmpdir=$(mktemp -d /tmp/issue23.XXXXX)
    tgt="$tmpdir/imports/does/not/exist/moo.json"
    run moo imports -o "$tgt" moo.jsonnet
    echo "$output"
    [ "$status" -eq 0 ]
    [ -s "$tgt" ]
    rm -rf $tmpdir
}

#!/usr/bin/env bats

srcdir="$(dirname $(realpath $BATS_TEST_DIRNAME))"

@test "locate model and template correctly" {
    cd "$srcdir"
    run moo -T buildsys/make -M buildsys/make render-deps -t model-dump.txt -o /dev/stdout model.jsonnet dump.txt.j2
    echo "$output"
    [ "$status" -eq 0 ]
    [ "$output" != "0.8" ]
    [ "$(echo -e "$output" | tr ' ' '\n' | grep model.jsonnet)" != "$srcdir/model.jsonnet" ]

}

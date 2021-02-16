#!/usr/bin/env bats

validate () {
    local want="$1"
    local WANT="$(echo $want | tr [:lower:] [:upper:])"
    local tfile="$BATS_TEST_DIRNAME/issue17-object.jsonnet"

    local num="$(moo -D $want.jschema compile $tfile | jq length)"

    local res=$(moo -D "$want".model validate --passfail --sequence \
                    -S "$want".jschema -s "$tfile" "$tfile")
    [ -n "$res" ]
    [ "$(echo -e "$res" | grep -c $WANT)" -eq $num ]
}

@test "check passing" {
    validate pass 
}

@test "check failing" {
    validate fail
}


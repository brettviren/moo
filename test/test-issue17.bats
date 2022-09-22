#!/usr/bin/env bats

validate () {
    local kind="$1"
    like="true"
    hate="false"
    if [ "$kind" = "fail" ] ; then
        like="false"
        hate="true"
    fi
    
    local tfile="$BATS_TEST_DIRNAME/issue17.jsonnet"

    local num="$(moo compile ${kind}.schema:$tfile | jq length)"

    local res=$(moo validate --passfail \
                    -s hier:$tfile \
                    -t ${kind}.schema:$tfile \
                    ${kind}.models:$tfile)

    [ -n "$res" ]
    [ "$(echo -e "$res" | grep -c $like)" -eq $num ]
    [ "$(echo -e "$res" | grep -c $hate)" -eq 0 ]
}

@test "check passing" {
    validate pass 
}

@test "check failing" {
    validate fail
}


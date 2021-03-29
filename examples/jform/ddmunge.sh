#!/bin/bash

usage () {
    cat <<EOF
Globally aggregate DUNE DAQ schema.

It needs "moo" in your path.  See also ddforms.py.

It can use a centrally installed DUNE DAQ release or take schema from
a development area.  

For the latter, it may be convenient to get source as: 

  $ git clone --recursive git@github.com:brettviren/dunedaqsrc.git

If out of date, one can get develop HEADs with:

  $ cd dunedaqsrc
  $ git submodule foreach git pull origin develop

or, pick a certain meta release tag/branch if there is one.

Then:

  $ $0 [cmd] [opts]

With commands:
EOF
    
    for one in $(grep '^cmd_' $0 | grep -v 'thecmd' | sed -e 's/cmd_//' -e 's/ .*//')
    do
        echo -e "\t$one"
    done

    exit -1
}

set -e

join2 () {
    sep="$1" ; shift
    array=$@
    echo "${array[0]}$(printf "$sep%s" "${array[@]:1}")"
}


join() {
    # $1 is return variable name
    # $2 is sep
    # $3... are the elements to join
    local retname=$1 sep=$2 ret=$3
    shift 3 || shift $(($#))
    printf -v "$retname" "%s" "$ret${@/#/$sep}"
}

# monolith /path/to/prefix > packages.jsonnet 2> moo_load_path.env
cmd_monolith () {
    top="$1" ; shift
    declare -a dirs
    declare -a imports
    declare -a items
    for sdir in $(find -L "$top" -name schema -type d)
    do
        dirs+=( "$(realpath $sdir)" )
        cd $sdir
        if [ -z "$(ls)" ] ; then
            continue
        fi
        for one in $(grep -H -c sort_select */*.jsonnet | grep -v :0)
        do
            clean="${one//:*/}"
            pkg=$(dirname "$clean")
            pi=$(basename "$clean" .jsonnet)
            #echo "$sdir|$one|$clean|$pkg|$pi" 1>&2

            imp="local ${pkg}_${pi} = import \"$clean\";"
            imports+=( "$imp" )

            rec="{package:\"$pkg\", plugin:\"$pi\", schema:${pkg}_${pi}}"
            items+=( "$rec" )
        done
        cd - > /dev/null 2>&1
    done

    join envvar ":" "${dirs[@]}"
    echo "export MOO_LOAD_PATH=$envvar" 1>&2

    join top "\n" "${imports[@]}"
    join body ",\n\t" "${items[@]}"
    echo -e "${top}\n[\n\t${body}\n]"
}

cmd_winnow () {
    cat $1 | grep -v appfwk | grep -v cmdlib
}

cmd_help () {
    usage
}

if [ -z "$1" ] ; then
    usage
fi

thecmd=$1 ; shift
cmd_$thecmd $@

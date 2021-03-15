#!/bin/bash

set -e
# set -x

usage () {
    cat <<EOF
Make a "schema pack" holding DUNE DAQ schema converted to jsonform and in a layout for the WEB UI.  This is an utter hack.

To use, make sure moo is in your path and:

  $ git clone --recursive git@github.com:brettviren/dunedaqsrc.git
  $ mkddschemapack.sh dunedaqsrc for-webui

EOF
    exit -1
}
if [ -z "$1" ] ; then
    usage
fi

srcdir="$1" ; shift

outdir="${1:-.}"
outdir="$(realpath $outdir)"

cd "$srcdir"

topname () {
    local got="$1"
    local parent="$(dirname "$got")"
    if [ "$parent" = "." ] ; then
        basename "$got"
        return
    fi
    topname "$parent"
}

for one in $(find "." -name '*.jsonnet' | grep '/schema/' | grep -v '/build/')
do
    if [[ "$one" == *"/build/"* ]] ; then
        continue;
    fi
    if [ "$(grep -c '"Conf"' "$one")" -eq 0 ] ; then
        continue
    fi

    base="$(basename "$one" .jsonnet)"
    pkgname="$(topname "$one")"
    there="${outdir}/${pkgname}/${base}"
    jf="$there/${pkgname}-${base}-schema.json"

    echo -e "$one\n-->\n$jf\n"

    mkdir -p "$there"
    
    moo -M "$pkgname" \
        -M appfwk/schema \
        -A typeref="dunedaq.${pkgname}.${base}.Conf" \
        -A types="$one" \
        compile moo2jsonform.jsonnet \
        > $jf

done

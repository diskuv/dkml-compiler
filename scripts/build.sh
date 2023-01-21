#!/bin/sh
set -euf

usage() {
    printf "usage: build.sh -p PREFIX -s SCRIPT\n" >&2
}

PREFIX=
SCRIPT=
while getopts ":hp:s:" opt; do
    case ${opt} in
        h ) usage; exit 0 ;;
        p ) PREFIX="$OPTARG" ;;
        s ) SCRIPT="$OPTARG" ;;
        \? )
            echo "This is not an option: -$OPTARG" >&2
            usage
            exit 2
        ;;
    esac
done
shift $((OPTIND -1))

if [ -z "$PREFIX" ]; then usage; exit 2; fi
if [ -z "$SCRIPT" ]; then usage; exit 2; fi

# Run script
cd "$PREFIX"
"share/dkml/repro/100co/vendor/dkml-compiler/src/$SCRIPT"

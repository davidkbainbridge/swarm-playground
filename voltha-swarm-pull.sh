#!/bin/bash


PROG=$(basename $0)
BASE_DIR=$(pwd)

usage() {
    echo >&2 "$PROG: [-d <dir>] [-h]"
    echo >&2 "  -d <dir>        directory in which the 'compose file directory' is located, defaults to '$(pwd)'"
    echo >&2 "  -h              this message"
}

OPTIND=1
while getopts d:h OPT; do
    case "$OPT" in
        d) BASE_DIR="$OPTARG";;
        h) usage;
           exit 1;;
        esac
done

for i in $(grep "^\ *image:" $BASE_DIR/compose/*.yml  | awk '{print $3}' | sort -u); do
    docker pull $i;
done

#!/bin/sh

targetdir=$1
shift

echo -- ---------------------
echo Arguments:
echo "  Target directory = $targetdir"
echo -- ---------------------

install -d "$targetdir"

install \
    env/META \
    env/github-actions-ci-to-ocaml-configure-env.sh \
    env/standard-compiler-env-to-ocaml-configure-env.sh \
    "$targetdir"

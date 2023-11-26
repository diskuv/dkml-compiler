#!/bin/sh
set -euf
ARCH=$1
shift
EXT=$1
shift

SRC="dl/$ARCH-ocamlc.opt$EXT"
if [ -e "$SRC" ]; then
    install -d dkmldir/vendor/dkml-compiler/bin
    install "$SRC" dkmldir/vendor/dkml-compiler/bin/bootstrap-ocamlc.opt.exe
fi

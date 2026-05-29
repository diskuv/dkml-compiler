#!/bin/sh
# This is a clone of https://github.com/ocaml/opam/blob/012103bc52bfd4543f3d6f59edde91ac70acebc8/shell/check_linker,
# with some shellcheck linting fixes applied.
# Licensed under https://github.com/ocaml/opam/blob/012103bc52bfd4543f3d6f59edde91ac70acebc8/LICENSE - LGPL 2.1 with special linking exceptions

# Ensure that the Microsoft Linker isn't being messed up by /usr/bin/link
FIRST=1
FAULT=0
PREPEND=
CHECK_LINKER_TMP=.r-c-ocaml-check_linker.$$
trap 'rm -f "$CHECK_LINKER_TMP"' 0 1 2 15
which --all link > "$CHECK_LINKER_TMP"
while IFS= read -r line; do
  OUTPUT=$("$line" --version 2>/dev/null | head -1 | grep -F "Microsoft (R) Incremental Linker")
  if [ "$OUTPUT" = "" ] && [ $FIRST -eq 1 ] ; then
    FAULT=1
  elif [ $FAULT -eq 1 ] ; then
    PREPEND=$(dirname "$line"):
    FAULT=0
  fi
done < "$CHECK_LINKER_TMP"

echo "$PATH_PREPEND$PREPEND"

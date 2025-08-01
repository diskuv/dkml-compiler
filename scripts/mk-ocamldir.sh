#!/bin/sh
set -euf

# Files already present in .opam extra-source
if [ ! -e dl/ocaml.tar.gz ]; then
    install -d dl
    curl -Lo dl/ocaml.tar.gz https://github.com/ocaml/ocaml/archive/4.14.2.tar.gz
fi
if [ ! -e dl/flexdll.tar.gz ]; then
    install -d dl
    curl -Lo dl/flexdll.tar.gz https://github.com/ocaml/flexdll/archive/0.43.tar.gz
fi

# OCaml source code
"install" "-d" "dl/ocaml/flexdll"
"tar" "xCfz" "dl/ocaml"          "dl/ocaml.tar.gz"   "--strip-components=1"
"tar" "xCfz" "dl/ocaml/flexdll"  "dl/flexdll.tar.gz" "--strip-components=1"

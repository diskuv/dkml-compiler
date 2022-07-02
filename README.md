# dkml-compiler

POSIX Bourne shell scripts to compile the DKML distribution of OCaml.

## Packages that rely on dkml-compiler

* dkml-component-ocamlcompiler
* dkml-component-ocamlrun
* dkml-component-opam
* dkml-runtime-apps

## Developing

You'll first want to download everything that the `.opam` downloads. Do that
with:

```bash
rm -rf dl ; git restore dl/.gitkeep
opam install ./dkml-base-compiler.opam --inplace-build --update-invariant
```

Then make a baseline of the OCaml source code that can be used for patching:

```
cd dl/ocaml
git init
git config core.safecrlf false
git add -A
```

## Status

[![Syntax check](https://github.com/diskuv/dkml-compiler/actions/workflows/syntax.yml/badge.svg)](https://github.com/diskuv/dkml-compiler/actions/workflows/syntax.yml)

# dkml-compiler

POSIX Bourne shell scripts to compile the DKML distribution of OCaml.

There is also a `dkml-base-compiler.opam` that always compiles the latest
DKML supported compiler. However the `dkml-compiler` repository ~~supports~~
will support more than one version of OCaml; you can get other versions by
adding the [diskuv-opam-repository](https://github.com/diskuv/diskuv-opam-repository#readme)
to your Opam switch.

The `diskuv-opam-repository` is also necessary if you want to use a DKML
version of the OCaml 4.x compiler on a non-Windows machine. The central Opam
repository only introduced the DKML distribution in OCaml 5.x generally and
OCaml 4.12 for Windows specifically.

## Packages that rely on dkml-compiler

* dkml-component-ocamlcompiler
* dkml-component-ocamlrun
* dkml-component-opam
* dkml-runtime-apps

## Directory Structure

### Build Directories

| Path                               | Description                                                        |
| ---------------------------------- | ------------------------------------------------------------------ |
| `dl/*.tar.gz`                      | Opam extra-source downloads                                        |
| `dl/ocaml`                         | Unpatched OCaml source from `dl/ocaml.tar.gz`                      |
| `dl/ocaml/flexdll`                 | Unpatched flexdll source from `dl/flexdll.tar.gz`                  |
| `dkmldir/.dkmlroot`                | Properties file with the version of DKML based on the Opam version |
| `dkmldir/vendor/dkml-compiler/src` | A copy of the toplevel `src/`                                      |
| `dkmldir/vendor/drc`               | Source from `dl/dkml-runtime-common.tar.gz`                        |

### Opam Directories

| Path                                                                  | Description                                 |
| --------------------------------------------------------------------- | ------------------------------------------- |
| `$(opam var prefix)/src-ocaml`                                        | OCaml source patched for the host ABI       |
| `$(opam var prefix)/bin`                                              | OCaml host ABI binaries. Ex. `ocamlopt`     |
| `$(opam var prefix)/lib/ocaml`                                        | OCaml host ABI libraries. Ex. `unix.cmxa`   |
| `$(opam var prefix)/share/dkml-base-compiler/mlcross/<ABI>/src-ocaml` | OCaml source patched for the target ABI     |
| `$(opam var prefix)/share/dkml-base-compiler/mlcross/<ABI>/bin`       | OCaml target ABI binaries. Ex. `ocamlopt`   |
| `$(opam var prefix)/share/dkml-base-compiler/mlcross/<ABI>/lib/ocaml` | OCaml target ABI libraries. Ex. `unix.cmxa` |

All ABI names are compatible with [dkml-c-probe](https://github.com/diskuv/dkml-c-probe#readme).
The target ABI folders will not be present if DKML does not support cross-compiling
on the host ABI. Currently only macOS has a target ABI.

There is another Opam package [conf-dkml-cross-toolchain](https://github.com/diskuv/conf-dkml-cross-toolchain)
that can take the "mlcross" Opam directory structure and add it to
`findlib` so that `ocamlfind -toolchain <ABI>` and `dune build -x <ABI>` work.

## Developing

You'll first want to recreate the [build directories](#build-directories)
that `dkml-base-compiler.opam` assembles. Do that with:

```bash
rm -rf dl ; git restore dl/.gitkeep
opam install ./dkml-base-compiler.opam --inplace-build --update-invariant
```

### Patching

In what follows, `VER` is a placeholder for the OCaml major version (ex. `4`)
*and* for the OCaml major+minor version in underscore formatting (ex. `4_12`).
The major version patches are applied first, and then the major+minor version
patches are applied.

The patches are all available in `src/p/`.
* The OCaml source patched for the host ABI uses `ocaml-common-VER-*.patch` in lexographical order
  and `ocaml-host-VER-*.patch` in lexographical order.
* The OCaml source patched for the target ABI uses `ocaml-common-VER-*.patch` in lexographical order
  and `ocaml-target-VER-*.patch` in lexographical order.

It is important to realize that patches are applied in a particular order, and
to structure the patches so they are more or less independent of each other.
**When you make a patch**, you should consult the [Opam directory structure table](#opam-directories)
and do a `git log` in the `OCaml source patched ...` directories.

## Status

[![Syntax check](https://github.com/diskuv/dkml-compiler/actions/workflows/syntax.yml/badge.svg)](https://github.com/diskuv/dkml-compiler/actions/workflows/syntax.yml)

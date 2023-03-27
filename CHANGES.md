# Changes

## Pending

* Install `flexdll[_initer]_msvc[64].obj` to `bin/` alongside existing
  `flexlink.exe` so that flexlink can run standalone without setting
  FLEXDIR environment variable. Bug report at
  <https://github.com/diskuv/dkml-installer-ocaml/issues/40>
* Fix ARM32 bug from ocaml/ocaml PR8936 that flipped a GOT relocation
  label with a PIC relocation label.

## `4.14.0~v1.2.0`

* Add `/DEBUG:FULL` to MSVC linker and `-Zi -Zd` to MSVC assembler, plus
  existing `-Z7` in MSVC compiler, when `dkml-option-debuginfo` is present

## `4.14.0~v1.1.0`

* OCaml 4.14.0
* Include experimental `ocamlnat`

## `4.12.1~v1.0.2`

* Support `ocaml-option-32bit`
* Do a true cross-compile on macOS/arm64 albeit not user friendly

## `4.12.1~v1.0.1`

## `4.12.1~v1.0.0`

* Initial version in Opam.

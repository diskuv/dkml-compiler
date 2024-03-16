# Changes

## Pending

* Upgrade OCaml compiler to 4.14.2
* Accept repeated `-m` and `-n` options
* Accept environment variables `DKML_HOST_OCAML_CONFIGURE` and
  `DKML_TARGET_OCAML_CONFIGURE` to do configure flags like
  `DKML_HOST_OCAML_CONFIGURE=--enable-imprecise-c99-float-ops`

## 2.1.0

* Fix bug where the cross-compiler `ocaml` interpreter was hardcoded to the
  cross-compiled standard library rather than the host standard library.

## 2.0.3

* Upgraded from `flexdll.0.42` to `flexdll.0.43`
* Install `flexdll[_initer]_msvc[64].obj` to `bin/` alongside existing
  `flexlink.exe` so that flexlink can run standalone without setting
  FLEXDIR environment variable. Bug report at
  <https://github.com/diskuv/dkml-installer-ocaml/issues/40>
* Fix ARM32 bug from ocaml/ocaml PR8936 that flipped a GOT relocation
  label with a PIC relocation label.
* When `dkml-option-debuginfo` is installed, keep assembly code available
  for any debug involving Stdlib and Runtime. When not installed,
  don't generate the `ocamlrund` and `ocamlruni` executables
* Remove `-i` and `-j` options for `r-c-ocaml-1-setup.sh` which were only
  active during cross-compilation, and unused except for now redundant
  debug options.
* Add `-g -O0` for Linux when `dkml-option-debuginfo` is present

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

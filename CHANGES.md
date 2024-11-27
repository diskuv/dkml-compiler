# Changes

## Pending

* Support vendor-supplied patches for flexdll 0.43 and unreleased 0.44. Patches are
  now relative to ocaml parent directory so all `git am` based patches are of form
  `flexdll/flexdll.c`, etc. to make robust to the lack of `flexdll/.git`.
   Vendor supplied patches are used by DkSDK CMake's `110-ocaml-lang`.
* Supply `DKML_HOST_ABI` to post-transform configure scripts.
* bugfix: De-duplicate consecutive ARM32 label. <https://github.com/diskuv/dkml-compiler/issues/6>
* The environment vars in android-ndk-env-to-ocaml-configure-env.sh now have the
  same naming as Android NDK's CMake variables.
  * `ANDROID_API` is now `ANDROID_PLATFORM`
    and supports the formats `android-$API_LEVEL`, `$API_LEVEL` or `android-$API_LETTER`
    as per <https://developer.android.com/ndk/guides/cmake#android_platform>.
  * `ANDROID_NDK_LATEST_HOME` is now `ANDROID_NDK`.
* opam global or switch vars `ANDROID_PLATFORM` and `ANDROID_NDK` will be read
  by dkml-base-compiler. <https://github.com/diskuv/dkml-compiler/issues/7>
* The `lib/findlib.conf.d/<TARGETABI>` findlib configuration is generated for all cross-compilers.
* Remove `-O0` from `/usr/bin/as` when `dkml-option-debuginfo` is present since `GNU as 2.30` does not support it.

## 2.1.3

* Backport from 5.2.0 of [Linear computation of closure environments](https://github.com/ocaml/ocaml/pull/12222)
  to fix performance bug <https://discuss.ocaml.org/t/scaling-factors-when-compiling-mutually-recursive-definitions/14708>

## 2.1.1

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

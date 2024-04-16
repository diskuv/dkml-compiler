#!/bin/sh

targetdir=$1
shift

echo -- ---------------------
echo Arguments:
echo "  Target directory = $targetdir"
echo -- ---------------------

install -d "$targetdir"
install -v dkml-compiler-src.META "$targetdir/META"

install -d "$targetdir/src"
install -v \
    src/r-c-ocaml-1-setup.sh \
    src/r-c-ocaml-2-build_host.sh \
    src/r-c-ocaml-3-build_cross.sh \
    src/r-c-ocaml-9-trim.sh \
    src/r-c-ocaml-README.md \
    src/r-c-ocaml-check_linker.sh \
    src/r-c-ocaml-functions.sh \
    src/r-c-ocaml-get_sak.make \
    src/version.ocaml.txt \
    src/version.semver.txt \
    "$targetdir/src"

install -d "$targetdir/src/f"
install -v \
    src/f/setjmp.asm \
    "$targetdir/src/f"

install -d "$targetdir/src/p"
install -v \
    src/p/flexdll-cross-0_39-a01-arm64.patch \
    src/p/flexdll-cross-0_42-a01-arm64.patch \
    src/p/ocaml-common-4_12-a01-alignfiletime.patch \
    src/p/ocaml-common-4_14_0-a01-fmatest.patch \
    src/p/ocaml-common-4_14-a01-alignfiletime.patch \
    src/p/ocaml-common-4_14-a02-nattop.patch \
    src/p/ocaml-common-4_14-a03-keepasm.patch \
    src/p/ocaml-common-4_14-a04-xdg.patch \
    src/p/ocaml-common-4_14-a05-msvccflags.patch \
    src/p/ocaml-cross-4_12-a01.patch \
    src/p/ocaml-cross-4_12-a02-arm32.patch \
    src/p/ocaml-cross-4_12unused-zzz-win32arm.patch \
    src/p/ocaml-cross-4_13-a01.patch \
    src/p/ocaml-cross-4_14_0-a02-arm32.patch \
    src/p/ocaml-cross-4_14_2-a02-arm32.patch \
    src/p/ocaml-cross-4_14-a01.patch \
    src/p/ocaml-cross-5_00_a02-arm32.patch \
    "$targetdir/src/p"

install -d "$targetdir/env"
install -v \
    env/github-actions-ci-to-ocaml-configure-env.sh \
    env/standard-compiler-env-to-ocaml-configure-env.sh \
    "$targetdir/env"

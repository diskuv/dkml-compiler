#!/bin/sh
set -euf

SEMVER=$1; shift
DRC=$1; shift

#   <dkmldir>/.dkmlroot
#     4.14.0~v0.4.1          --dkml-semver--> 0.4.1
#     4.14.0~v0.4.1~prerel69 --dkml-semver--> 0.4.1-prerel69
if [ -z "$SEMVER" ]; then
    # In development use version.semver.xt
    SEMVER=$(tr -d '\r' < src/version.semver.txt)
fi
install -d dkmldir
printf 'dkml_root_version=%s\n' "$SEMVER" | sed 's/[0-9.]*~v//; s/~/-/' > dkmldir/.dkmlroot

#   <dkmldir>/vendor/drc/
if [ -z "$DRC" ]; then
    # In development clone the dkml-runtime-common project
    install -d dkmldir/vendor
    if [ -d dkmldir/vendor/drc ]; then
        git -C dkmldir/vendor/drc pull --ff-only
    else
        git -C dkmldir/vendor clone https://github.com/diskuv/dkml-runtime-common.git drc
    fi
else
    # In opam copy the dkml-runtime-common dependency
    #     tar through pipe is essentially an rsync (without requiring rsync)
    install -d dkmldir/vendor/drc
    tar cCf "$DRC/" - . | tar xCf dkmldir/vendor/drc/ -
fi

#   <dkmldir>/vendor/dkml-compiler/env
install -d dkmldir/vendor/dkml-compiler/env
#     only the standard compiler environment is needed for the base compiler. However options play a part.
#     we install unpatched options, and edit them as needed if inside opam
install "env/standard-compiler-env-to-ocaml-configure-env.sh" "dkmldir/vendor/dkml-compiler/env/"
install "env/android-ndk-env-to-ocaml-configure-env.sh" "dkmldir/vendor/dkml-compiler/env/"

#   <dkmldir>/vendor/dkml-compiler/src
#     tar through pipe is essentially an rsync (without requiring rsync)
rm -rf dkmldir/vendor/dkml-compiler/src
install -d dkmldir/vendor/dkml-compiler/src
tar cCf src/ - . | tar xCf dkmldir/vendor/dkml-compiler/src/ -

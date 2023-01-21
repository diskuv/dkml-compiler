#!/bin/sh
set -euf

usage() {
    echo "'--opam-package OPAM_PACKAGE.opam'" >&2
    exit 3
}
OPTION=$1
shift
[ "$OPTION" = "--opam-package" ] || usage
OPAM_PACKAGE=$1
shift

if [ -x /usr/bin/cygpath ]; then
    opamroot_unix=$(/usr/bin/cygpath -au "${opam_root}")
else
    opamroot_unix="${opam_root}"
fi

# shellcheck disable=SC2154
echo "
=============
build-test.sh
=============
.
---------
Arguments
---------
OPAM_PACKAGE=$OPAM_PACKAGE
.
------
Matrix
------
dkml_host_abi=$dkml_host_abi
abi_pattern=$abi_pattern
opam_root=$opam_root
exe_ext=${exe_ext:-}
.
-------
Derived
-------
opamroot_unix=${opamroot_unix}
.
"

# PATH. Add opamrun
if [ -n "${CI_PROJECT_DIR:-}" ]; then
    export PATH="$CI_PROJECT_DIR/.ci/sd4/opamrun:$PATH"
elif [ -n "${PC_PROJECT_DIR:-}" ]; then
    export PATH="$PC_PROJECT_DIR/.ci/sd4/opamrun:$PATH"
elif [ -n "${GITHUB_WORKSPACE:-}" ]; then
    export PATH="$GITHUB_WORKSPACE/.ci/sd4/opamrun:$PATH"
else
    export PATH="$PWD/.ci/sd4/opamrun:$PATH"
fi

# Initial Diagnostics
opamrun switch
opamrun list
opamrun var
opamrun config report
opamrun exec -- ocamlc -config
xswitch=$(opamrun var switch)
if [ -x /usr/bin/cypgath ]; then
    xswitch=$(/usr/bin/cygpath -au "$xswitch")
fi
if [ -e "$xswitch/src-ocaml/config.log" ]; then
    echo '--- BEGIN src-ocaml/config.log ---' >&2
    cat "$xswitch/src-ocaml/config.log" >&2
    echo '--- END src-ocaml/config.log ---' >&2
fi

# Update
if ! [ "${SKIP_OPAM_INSTALL:-}" = ON ]; then
  opamrun update
fi

# Build and test
OPAM_PKGNAME=${OPAM_PACKAGE%.opam}
if ! [ "${SKIP_OPAM_INSTALL:-}" = ON ]; then
  opamrun install "./${OPAM_PKGNAME}.opam" --with-test --yes
fi

# Copy the installed bin/, lib/, share/ and src-ocaml/ from 'dkml' Opam switch
# into dist/ folder:
#
# dist/
#   <dkml_host_abi>/
#      <file1>
#      ...
#
# For GitHub Actions specifically the structure is:
#
# dist/
#    <file1>
#      ...
# since the ABI should be the uploaded artifact name already in .github/workflows:
#   - uses: actions/upload-artifact@v3
#     with:
#       name: ${{ matrix.dkml_host_abi }}
#       path: dist/

if [ -n "${GITHUB_ENV:-}" ]; then
    DIST=dist
else
    DIST="dist/${dkml_host_abi}"
fi
install -d "${DIST}" "stage"
#   Copy installation into stage/
for d in bin lib share/doc share/ocaml-config; do
    echo "Copying $d ..."
    ls -l "${opam_root}/dkml/$d/"
    rm -rf "stage/${d:?}/"
    install -d "stage/$d/"
    rsync -a "${opamroot_unix}/dkml/$d/" "stage/$d"
done
#   For Windows you must ask your users to first install the vc_redist executable.
#   Confer: https://github.com/diskuv/dkml-workflows#distributing-your-windows-executables
case "${dkml_host_abi}" in
windows_x86_64) wget -O "stage/bin/vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe ;;
windows_x86) wget -O "stage/bin/vc_redist.x86.exe" https://aka.ms/vs/17/release/vc_redist.x86.exe ;;
windows_arm64) wget -O "stage/bin/vc_redist.arm64.exe" https://aka.ms/vs/17/release/vc_redist.arm64.exe ;;
esac

# Final Diagnostics
case "${dkml_host_abi}" in
linux_*)
    if command -v apk; then
        apk add file
    fi ;;
esac
file "stage/bin/ocamlc.opt${exe_ext:-}"

# Zip up everything in stage/, and put into DIST
case "${dkml_host_abi}" in
windows_*)
    if command -v pacman; then
        pacman -Sy --noconfirm --needed zip
    fi ;;
esac
set -x
cd "stage"
  tar cfz "../${DIST}/dkml-compiler.tar.gz" .
  zip -rq "../${DIST}/dkml-compiler.zip" .
cd ..

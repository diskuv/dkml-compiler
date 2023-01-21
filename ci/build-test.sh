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
opamrun update

# Build and test
OPAM_PKGNAME=${OPAM_PACKAGE%.opam}
opamrun install "./${OPAM_PKGNAME}.opam" --with-test --yes

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
STAGE=stage
install -d "${DIST}" "${STAGE}"
#   Copy executable into stage/
for d in bin lib share src-ocaml; do
    ls -l "${opam_root}/dkml/$d/"
    cp -rp "${opam_root}/dkml/$d/" "${STAGE}/"
done
#   For Windows you must ask your users to first install the vc_redist executable.
#   Confer: https://github.com/diskuv/dkml-workflows#distributing-your-windows-executables
case "${dkml_host_abi}" in
windows_x86_64) wget -O "${STAGE}/vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe ;;
windows_x86) wget -O "${STAGE}/vc_redist.x86.exe" https://aka.ms/vs/17/release/vc_redist.x86.exe ;;
windows_arm64) wget -O "${STAGE}/vc_redist.arm64.exe" https://aka.ms/vs/17/release/vc_redist.arm64.exe ;;
esac

# Final Diagnostics
case "${dkml_host_abi}" in
linux_*)
    if command -v apk; then
        apk add file
    fi ;;
esac
file "${STAGE}/bin/ocamlc.opt${exe_ext:-}"

# Zip up everything in stage/, and put into DIST
OLDDIR=$(pwd)
cd "${STAGE}"
  tar cfz "${OLDDIR}/${DIST}/dkml-compiler.tar.gz" .
  zip -rq "${OLDDIR}/${DIST}/dkml-compiler.zip" .
cd "${OLDDIR}"

#!/bin/sh
set -euf

OPAM_PACKAGE=dkml-base-compiler.opam

if [ -x /usr/bin/cygpath ]; then
    # shellcheck disable=SC2154
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
elif [ -d .ci/sd4/opamrun ]; then
    export PATH="$PWD/.ci/sd4/opamrun:$PATH"
else
    # allow testing from command line.
    # ex:
    #   opam pin dkml-base-compiler git+file://$PWD/.git#$(git rev-parse HEAD) --yes --no-action
    #   opam_root=$(opam var root) dkml_host_abi=darwin_x86_64 abi_pattern=macos-darwin_all SKIP_OPAM_UPDATE=ON sh ci/build-test.sh
    opamrun() {
        opam "$@"
    }
fi

# Initial Diagnostics
opamrun switch
opamrun list
opamrun var
opamrun config report

# Update
if ! [ "${SKIP_OPAM_INSTALL:-}" = ON ]; then
  if ! [ "${SKIP_OPAM_UPDATE:-}" = ON ]; then
    opamrun update
  fi
fi

# Build and test
OPAM_PKGNAME=${OPAM_PACKAGE%.opam}
if ! [ "${SKIP_OPAM_INSTALL:-}" = ON ]; then
  opamrun install "./${OPAM_PKGNAME}.opam" conf-dkml-cross-toolchain --with-test --yes
fi

# Copy the installed binaries (including cross-compiled ones) from Opam into dist/ folder.
# Name the binaries with the target ABI since GitHub Releases are flat namespaces.
prefix=$(opamrun var prefix)
opamrun exec -- sh ci/package-build.sh "$dkml_host_abi" "$prefix"

# For Windows you must ask your users to first install the vc_redist executable.
# Confer: https://github.com/diskuv/dkml-workflows#distributing-your-windows-executables
case "${dkml_host_abi}" in
windows_x86_64) wget -O dist/vc_redist.x64.exe https://aka.ms/vs/17/release/vc_redist.x64.exe ;;
windows_x86) wget -O dist/vc_redist.x86.exe https://aka.ms/vs/17/release/vc_redist.x86.exe ;;
windows_arm64) wget -O dist/vc_redist.arm64.exe https://aka.ms/vs/17/release/vc_redist.arm64.exe ;;
esac

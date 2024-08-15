#!/bin/bash
# ----------------------------
# Copyright 2021 Diskuv, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------
#
# @jonahbeckford: 2021-10-26
# - This file is licensed differently than the rest of the DkML distribution.
#   Keep the Apache License in this file since this file is part of the reproducible
#   build files.
#
######################################
# r-c-ocaml-1-setup.sh -d DKMLDIR -t TARGETDIR \
#      -v COMMIT [-a TARGETABIS]
#
# Sets up the source code for a reproducible compilation of OCaml

set -euf

# ------------------
# BEGIN Command line processing

BINARIES=(
    flexlink
    ocaml
    ocamlc.byte
    ocamlc
    ocamlc.opt
    ocamlcmt
    ocamlcp.byte
    ocamlcp
    ocamlcp.opt
    ocamldebug
    ocamldep.byte
    ocamldep
    ocamldep.opt
    ocamldoc
    ocamldoc.opt
    ocamllex.byte
    ocamllex
    ocamllex.opt
    ocamlmklib.byte
    ocamlmklib
    ocamlmklib.opt
    ocamlmktop.byte
    ocamlmktop
    ocamlmktop.opt
    ocamlnat
    ocamlobjinfo.byte
    ocamlobjinfo
    ocamlobjinfo.opt
    ocamlopt.byte
    ocamlopt
    ocamlopt.opt
    ocamloptp.byte
    ocamloptp
    ocamloptp.opt
    ocamlprof.byte
    ocamlprof
    ocamlprof.opt
    ocamlrun
    ocamlrund
    ocamlruni
    ocamlyacc
)
# Since installtime/windows/Machine/Machine.psm1 has minimum VS14 we only select that version
# or greater. We'll ignore '10.0' (Windows SDK 10) which may bundle Visual Studio 2015, 2017 or 2019.
# Also we do _not_ use the environment (ie. no '@' in MSVS_PREFERENCE) since that isn't reproducible,
# and also because it sets MSVS_* variables to empty if it thinks the environment is correct (but we
# _always_ want MSVS_* set since OCaml ./configure script branches on MSVS_* being non-empty).
OPT_MSVS_PREFERENCE='VS16.*;VS15.*;VS14.0' # KEEP IN SYNC with 2-build.sh
HOST_SUBDIR=.
HOSTSRC_SUBDIR=src/ocaml
CROSS_SUBDIR=opt/mlcross

usage() {
    {
        printf "%s\n" "Usage:"
        printf "%s\n" "    r-c-ocaml-1-setup.sh"
        printf "%s\n" "        -h                       Display this help message."
        printf "\n"
        printf "%s\n" "Artifacts include (flexlink only on Windows, ocamlnat only on 4.14+):"
        for binary in "${BINARIES[@]}"; do
            printf "    %s\n" "$binary"
        done
        printf "\n"
        printf "%s\n" "The compiler for the host machine ('ABI') comes from the PATH (like /usr/bin/gcc) as detected by OCaml's ./configure"
        printf "%s\n" "script, except on Windows machines where https://github.com/metastack/msvs-tools#msvs-detect is used to search"
        printf "%s\n" "for Visual Studio compiler installations."
        printf "\n"
        printf "%s\n" "The expectation we place on any user of this script who wants to cross-compile is that they understand what an ABI is,"
        printf "%s\n" "and how to obtain a SYSROOT for their target ABI. If you want an OCaml cross-compiler, you will need to use"
        printf "%s\n" "the '-a TARGETABIS' option."
        printf "\n"
        printf "%s\n" "To generate 32-bit machine code from OCaml, the host ABI for the OCaml native compiler must be 32-bit. And to generate"
        printf "%s\n" "64-bit machine code from OCaml, the host ABI for the OCaml native compiler must be 64-bit. In practice this means you"
        printf "%s\n" "may want to pick a 32-bit cross compiler for your _host_ ABI (for example a GCC compiler in 32-bit mode on a 64-bit"
        printf "%s\n" "Intel host) and then set your _target_ ABI to be a different cross compiler (for example a GCC in 32-bit mode on a 64-bit"
        printf "%s\n" "ARM host). **You can and should use** a 32-bit or 64-bit cross compiler for your host ABI as long as it generates executables"
        printf "%s\n" "that can be run on your host platform. Apple Silicon is a common architecture where you cannot run 32-bit executables, so your"
        printf "%s\n" "choices for where to run 32-bit ARM executables are QEMU (slow) or a ARM64 board (limited memory; Raspberry Pi 4, RockPro 64,"
        printf "%s\n" "NVidia Jetson) or a ARM64 Snapdragon Windows PC with WSL2 Linux (limited memory) or AWS Graviton2 (cloud). ARM64 servers for"
        printf "%s\n" "individual resale are also becoming available."
        printf "\n"
        printf "%s\n" "Options"
        printf "%s\n" "   -d DIR: DKML directory containing a .dkmlroot file"
        printf "%s\n" "   -t DIR: Target directory for the reproducible directory tree"
        printf "%s\n" "   -v COMMIT_OR_DIR: Git commit or tag or directory for https://github.com/ocaml/ocaml. Strongly prefer a commit id"
        printf "%s\n" "      instead of a git tag for much stronger reproducibility guarantees"
        printf "%s\n" "   -u COMMIT: (Deprecated). Git commit or tag for https://github.com/ocaml/ocaml for the host ABI. Defaults to -v COMMIT"
        printf "%s\n" "   -c OCAMLC_OPT_EXE: Optional relative path from [-d DIR] to a possibly older 'ocamlc.opt'. It speeds up compilation"
        printf "%s\n" "      of the new OCaml compiler. If the executable does not exist it is not an error; it is silently dropped"
        printf "%s\n" "   -a TARGETABIS: Optional. A named list of self-contained Posix shell script that can be sourced to set the"
        printf "%s\n" "      compiler environment variables for the target ABI. If not specified then the OCaml environment"
        printf "%s\n" "      will be purely for the host ABI. All path should use the native host platform's path"
        printf "%s\n" "      conventions like '/usr' on Unix and 'C:\VS2019' on Windows, although relative paths from DKML dir are accepted"
        printf "%s\n" "      The format of TARGETABIS is: <DKML_TARGET_ABI1>=/path/to/script1;<DKML_TARGET_ABI2>=/path/to/script2;..."
        printf "%s\n" "      where:"
        printf "%s\n" "        DKML_TARGET_ABI - The target ABI"
        printf "%s\n" "          Values include: windows_x86, windows_x86_64, android_arm64v8a, darwin_x86_64, etc."
        printf "%s\n" "          Others are/will be documented on https://diskuv.gitlab.io/diskuv-ocaml"
        printf "%s\n" "      The Posix shell script will have an unexported \$DKMLDIR environment variable containing the directory"
        printf "%s\n" "        of .dkmlroot, and an unexported \$DKML_TARGET_ABI containing the name specified in the TARGETABIS option"
        printf "%s\n" "      The Posix shell script should set some or all of the following compiler environment variables:"
        printf "%s\n" "        PATH - The PATH environment variable. You can use \$PATH to add to the existing PATH. On Windows"
        printf "%s\n" "          which uses MSYS2, the PATH should be colon separated with each PATH entry a UNIX path like /usr/a.out"
        printf "%s\n" "        AS - The assembly language compiler that targets machine code for the target ABI. On Windows this"
        printf "%s\n" "          must be a MASM compiler like ml/ml64.exe"
        printf "%s\n" "        ASPP - The assembly language compiler and preprocessor that targets machine code for the target ABI."
        printf "%s\n" "          On Windows this must be a MASM compiler like ml/ml64.exe"
        printf "%s\n" "        CC - The C cross compiler that targets machine code for the target ABI"
        printf "%s\n" "        INCLUDE - For the MSVC compiler, the semicolon-separated list of standard C and Windows header"
        printf "%s\n" "          directories that should be based on the target ABI sysroot"
        printf "%s\n" "        LIB - For the MSVC compiler, the semicolon-separated list of C and Windows library directories"
        printf "%s\n" "          that should be based on the target ABI sysroot"
        printf "%s\n" "        COMPILER_PATH - For the GNU compiler (GCC), the colon-separated list of system header directories"
        printf "%s\n" "          that should be based on the target ABI sysroot"
        printf "%s\n" "        CPATH - For the CLang compiler (including Apple CLang), the colon-separated list of system header"
        printf "%s\n" "          directories that should be based on the target ABI sysroot"
        printf "%s\n" "        LIBRARY_PATH - For the GNU compiler (GCC) and CLang compiler (including Apple CLang), the"
        printf "%s\n" "          colon-separated list of system library directory that should be based on the target ABI sysroot"
        printf "%s\n" "        PARTIALLD - The linker and flags to use for packaging (ocamlopt -pack) and for partial links"
        printf "%s\n" "          (ocamlopt -output-obj); only used while compiling the OCaml environment. This value"
        printf "%s\n" "          forms the basis of the 'native_pack_linker' of https://ocaml.org/api/compilerlibref/Config.html"
        printf "%s\n" "   -b PREF: Required and used only for the MSVC compiler. This is the msvs-tools MSVS_PREFERENCE setting"
        printf "%s\n" "      needed to detect the Windows compiler for the host ABI. Not used when '-e DKMLHOSTABI' is specified."
        printf "%s\n" "      Defaults to '$OPT_MSVS_PREFERENCE' which, because it does not include '@',"
        printf "%s\n" "      will not choose a compiler based on environment variables that would disrupt reproducibility."
        printf "%s\n" "      Confer with https://github.com/metastack/msvs-tools#msvs-detect"
        printf "%s\n" "   -e DKMLHOSTABI: Optional. Use the DkML compiler detector find a host ABI compiler."
        printf "%s\n" "      Especially useful to find a 32-bit Windows host compiler that can use 64-bits of memory for the compiler."
        printf "%s\n" "      Values include: windows_x86, windows_x86_64, android_arm64v8a, darwin_x86_64, etc."
        printf "%s\n" "      Others are/will be documented on https://diskuv.gitlab.io/diskuv-ocaml. Defaults to an"
        printf "%s\n" "      the environment variable DKML_HOST_ABI, or if not defined then an autodetection of the host architecture."
        printf "%s\n" "   -k HOSTABISCRIPT: Optional. A self-contained Posix shell script relative to [-d DIR] that can be sourced to"
        printf "%s\n" "      set the compiler environment variables for the host ABI. See '-a TARGETABIS' for the shell script semantics."
        printf "%s\n" "   -l FLEXLINKFLAGS: Options added to flexlink while building ocaml, ocamlc, etc. native Windows executables"
        printf "%s\n" "   -m HOSTCONFIGUREARGS: Optional. Extra arguments passed to OCaml's ./configure for the host ABI. --with-flexdll"
        printf "%s\n" "      and --host will have already been set appropriately, but you can override the --host heuristic by adding it"
        printf "%s\n" "      to -m HOSTCONFIGUREARGS. Can be repeated."
        printf "%s\n" "   -n TARGETCONFIGUREARGS: Optional. Extra arguments passed to OCaml's ./configure for the target ABI. --with-flexdll"
        printf "%s\n" "      and --host will have already been set appropriately, but you can override the --host heuristic by adding it"
        printf "%s\n" "      to -n TARGETCONFIGUREARGS. Can be repeated."
        printf "%s\n" "   -r Only build ocamlrun, Stdlib and the other libraries. Cannot be used with -a TARGETABIS."
        printf "%s\n" "   -f HOSTSRC_SUBDIR: Optional. Use HOSTSRC_SUBDIR subdirectory of -t DIR to place the source code of the host ABI."
        printf "%s\n" "      Defaults to $HOSTSRC_SUBDIR"
        printf "%s\n" "   -p HOST_SUBDIR: Optional. Use HOST_SUBDIR subdirectory of -t DIR to place the host ABI. Defaults to $HOST_SUBDIR"
        printf "%s\n" "   -g CROSS_SUBDIR: Optional. Use CROSS_SUBDIR subdirectory of -t DIR to place target ABIs. Defaults to $CROSS_SUBDIR"
        printf "%s\n" "   -o TEMPLATE_DIR: Optional. Instead of fetching source code for HOSTSRC_SUBDIR and CROSS_SUBDIR from git and patching"
        printf "%s\n" "      CROSS_SUBDIR for cross-compilation, the source code is copied from TEMPLATE_DIR/HOSTSRC_SUBDIR and"
        printf "%s\n" "      TEMPLATE_DIR/CROSS_SUBDIR. The expectation is the template directory comes from a prior 1-setup.sh invocation; in"
        printf "%s\n" "      particular the patching has already been done"
        printf "%s\n" "   -w Disable non-essentials like the native toplevel and ocamldoc."
        printf "%s\n" "   -x Do not include temporary object files (only useful for debugging) in target directory"
        printf "%s\n" "   -z Do not include .git repositories in target directory"
    } >&2
}

SETUP_ARGS=()
BUILD_HOST_ARGS=()
BUILD_CROSS_ARGS=()
TRIM_ARGS=()

# Make repeatable environment variable specs
if [ -n "${DKML_HOST_OCAML_CONFIGURE:-}" ]; then
    SETUP_ARGS+=( -m "$DKML_HOST_OCAML_CONFIGURE" )
    BUILD_HOST_ARGS+=( -m "$DKML_HOST_OCAML_CONFIGURE" )
fi
if [ -n "${DKML_TARGET_OCAML_CONFIGURE:-}" ]; then
    SETUP_ARGS+=( -n "$DKML_TARGET_OCAML_CONFIGURE" )
    BUILD_CROSS_ARGS+=( -n "$DKML_TARGET_OCAML_CONFIGURE" )
fi

DKMLDIR=
DKMLHOSTABI=${DKML_HOST_ABI:-}
GIT_COMMITID_TAG_OR_DIR=
TARGETDIR=
TARGETABIS=
MSVS_PREFERENCE="$OPT_MSVS_PREFERENCE"
RUNTIMEONLY=OFF
TEMPLATEDIR=
HOSTABISCRIPT=
OCAMLC_OPT_EXE=
while getopts ":d:v:u:t:a:b:c:e:k:l:m:n:rf:p:g:o:wxzh" opt; do
    case ${opt} in
        h )
            usage
            exit 0
        ;;
        w ) SETUP_ARGS+=( -w )
            BUILD_HOST_ARGS+=( -w )
            BUILD_CROSS_ARGS+=( -w ) ;;
        d )
            DKMLDIR="$OPTARG"
            if [ ! -e "$DKMLDIR/.dkmlroot" ]; then
                printf "%s\n" "Expected a DKMLDIR at $DKMLDIR but no .dkmlroot found" >&2
                usage
                exit 1
            fi
            # Make into absolute path
            DKMLDIR_1=$(dirname "$DKMLDIR")
            DKMLDIR_1=$(cd "$DKMLDIR_1" && pwd)
            DKMLDIR_2=$(basename "$DKMLDIR")
            DKMLDIR="$DKMLDIR_1/$DKMLDIR_2"
        ;;
        v )
            GIT_COMMITID_TAG_OR_DIR="$OPTARG"
            SETUP_ARGS+=( -v "$GIT_COMMITID_TAG_OR_DIR" )
        ;;
        u )
            printf "WARNING: r-c-ocaml-1-setup.sh -u COMMIT is deprecated. Use -v option instead\n" >&2
        ;;
        t )
            TARGETDIR="$OPTARG"
            SETUP_ARGS+=( -t . )
            BUILD_HOST_ARGS+=( -t . )
            BUILD_CROSS_ARGS+=( -t . )
            TRIM_ARGS+=( -t . )
        ;;
        a )
            TARGETABIS="$OPTARG"
        ;;
        b )
            MSVS_PREFERENCE="$OPTARG"
            SETUP_ARGS+=( -b "$OPTARG" )
        ;;
        c)  OCAMLC_OPT_EXE="$OPTARG" ;;
        e )
            DKMLHOSTABI="$OPTARG"
        ;;
        f ) HOSTSRC_SUBDIR=$OPTARG ;;
        p ) HOST_SUBDIR=$OPTARG ;;
        g ) CROSS_SUBDIR=$OPTARG ;;
        l )
            BUILD_HOST_ARGS+=( -l "$OPTARG" )
            BUILD_CROSS_ARGS+=( -l "$OPTARG" )
        ;;
        k )
            HOSTABISCRIPT=$OPTARG
            SETUP_ARGS+=( -k "$OPTARG" )
            BUILD_HOST_ARGS+=( -k "$OPTARG" )
        ;;
        m )
            SETUP_ARGS+=( -m "$OPTARG" )
            BUILD_HOST_ARGS+=( -m "$OPTARG" )
        ;;
        n )
            SETUP_ARGS+=( -n "$OPTARG" )
            BUILD_CROSS_ARGS+=( -n "$OPTARG" )
        ;;
        r )
            SETUP_ARGS+=( -r )
            BUILD_HOST_ARGS+=( -r )
            RUNTIMEONLY=ON
        ;;
        o )
            SETUP_ARGS+=( -o "$OPTARG" )
            TEMPLATEDIR=$OPTARG
        ;;
        x )
            SETUP_ARGS+=( -x )
            TRIM_ARGS+=( -x )
        ;;
        z )
            SETUP_ARGS+=( -z )
            TRIM_ARGS+=( -z )
        ;;
        \? )
            printf "%s\n" "This is not an option: -$OPTARG" >&2
            usage
            exit 1
        ;;
    esac
done
shift $((OPTIND -1))

if [ -z "$DKMLDIR" ] || [ -z "$GIT_COMMITID_TAG_OR_DIR" ] || [ -z "$TARGETDIR" ]; then
    printf "%s\n" "Missing required options" >&2
    usage
    exit 1
fi
if [ "$RUNTIMEONLY" = ON ] && [ -n "$TARGETABIS" ]; then
    printf "-r and -a TARGETABIS cannot be used at the same time\n" >&2
    usage
    exit 1
fi

# END Command line processing
# ------------------

# shellcheck disable=SC2034
USERMODE=ON
# shellcheck disable=SC2034
STATEDIR=

# shellcheck disable=SC1091
. "$DKMLDIR/vendor/drc/unix/_common_tool.sh"

disambiguate_filesystem_paths

# Bootstrapping vars
TARGETDIR_UNIX=$(install -d "$TARGETDIR" && cd "$TARGETDIR" && pwd) # better than cygpath: handles TARGETDIR=. without trailing slash, and works on Unix/Windows
if [ -x /usr/bin/cygpath ]; then
    TARGETDIR_MIXED=$(/usr/bin/cygpath -am "$TARGETDIR_UNIX")
else
    TARGETDIR_MIXED="$TARGETDIR_UNIX"
fi

# Target subdirectories
case $HOSTSRC_SUBDIR in
/* | ?:*) # /a/b/c or C:\Windows
    if [ -x /usr/bin/cygpath ]; then
        HOSTSRC_SUBDIR_MIXED=$(/usr/bin/cygpath -m "$HOSTSRC_SUBDIR")
    else
        HOSTSRC_SUBDIR_MIXED="$HOSTSRC_SUBDIR"
    fi
    if [ "${HOSTSRC_SUBDIR##"$TARGETDIR_UNIX/"}" != "$HOSTSRC_SUBDIR" ]; then
        HOSTSRC_SUBDIR="${HOSTSRC_SUBDIR##"$TARGETDIR_UNIX/"}"
    elif [ "${HOSTSRC_SUBDIR_MIXED##"$TARGETDIR_MIXED/"}" != "$HOSTSRC_SUBDIR_MIXED" ]; then
        HOSTSRC_SUBDIR="${HOSTSRC_SUBDIR_MIXED##"$TARGETDIR_MIXED/"}"
    else
        printf "FATAL: Could not resolve HOSTSRC_SUBDIR=%s as a subdirectory of %s\n" "$HOSTSRC_SUBDIR" "$TARGETDIR_UNIX" >&2
        exit 107
    fi
esac
case $HOST_SUBDIR in
/* | ?:*) # /a/b/c or C:\Windows
    if [ -x /usr/bin/cygpath ]; then
        HOST_SUBDIR_MIXED=$(/usr/bin/cygpath -m "$HOST_SUBDIR")
    else
        HOST_SUBDIR_MIXED="$HOST_SUBDIR"
    fi
    if [ "${HOST_SUBDIR##"$TARGETDIR_UNIX/"}" != "$HOST_SUBDIR" ]; then
        HOST_SUBDIR="${HOST_SUBDIR##"$TARGETDIR_UNIX/"}"
    elif [ "${HOST_SUBDIR_MIXED##"$TARGETDIR_MIXED/"}" != "$HOST_SUBDIR_MIXED" ]; then
        HOST_SUBDIR="${HOST_SUBDIR_MIXED##"$TARGETDIR_MIXED/"}"
    else
        printf "FATAL: Could not resolve HOST_SUBDIR=%s as a subdirectory of %s\n" "$HOST_SUBDIR" "$TARGETDIR_UNIX" >&2
        exit 107
    fi
esac
case $CROSS_SUBDIR in
/* | ?:*) # /a/b/c or C:\Windows
    if [ -x /usr/bin/cygpath ]; then
        CROSS_SUBDIR_MIXED=$(/usr/bin/cygpath -m "$CROSS_SUBDIR")
    else
        CROSS_SUBDIR_MIXED="$CROSS_SUBDIR"
    fi
    if [ "${CROSS_SUBDIR##"$TARGETDIR_UNIX/"}" != "$CROSS_SUBDIR" ]; then
        CROSS_SUBDIR="${CROSS_SUBDIR##"$TARGETDIR_UNIX/"}"
    elif [ "${CROSS_SUBDIR_MIXED##"$TARGETDIR_MIXED/"}" != "$CROSS_SUBDIR_MIXED" ]; then
        CROSS_SUBDIR="${CROSS_SUBDIR_MIXED##"$TARGETDIR_MIXED/"}"
    else
        printf "FATAL: Could not resolve CROSS_SUBDIR=%s as a subdirectory of %s\n" "$CROSS_SUBDIR" "$TARGETDIR_UNIX" >&2
        exit 107
    fi
esac

# ensure git, if directory, is an absolute directory
if [ -d "$GIT_COMMITID_TAG_OR_DIR" ]; then
    if [ -x /usr/bin/cygpath ]; then
        GIT_COMMITID_TAG_OR_DIR=$(/usr/bin/cygpath -am "$GIT_COMMITID_TAG_OR_DIR")
    else
        # absolute directory
        buildhost_pathize "$GIT_COMMITID_TAG_OR_DIR"
        # shellcheck disable=SC2154
        GIT_COMMITID_TAG_OR_DIR="$buildhost_pathize_RETVAL"
    fi
fi

SETUP_ARGS+=( -p "$HOST_SUBDIR" -f "$HOSTSRC_SUBDIR" -g "$CROSS_SUBDIR" )
BUILD_HOST_ARGS+=( -p "$HOST_SUBDIR" -f "$HOSTSRC_SUBDIR" )
BUILD_CROSS_ARGS+=( -f "$HOSTSRC_SUBDIR" -g "$CROSS_SUBDIR" )
TRIM_ARGS+=( -f "$HOSTSRC_SUBDIR" -g "$CROSS_SUBDIR"  )

# To be portable whether we build scripts in a container or not, we
# change the directory to always be in the DKMLDIR (just like a container
# sets the directory to be /work)
cd "$DKMLDIR"

# Other dirs
if [ -x /usr/bin/cygpath ]; then
    OCAMLSRC_UNIX=$(/usr/bin/cygpath -au "$TARGETDIR_UNIX/$HOSTSRC_SUBDIR")
    OCAMLSRC_MIXED=$(/usr/bin/cygpath -am "$TARGETDIR_UNIX/$HOSTSRC_SUBDIR")
else
    OCAMLSRC_UNIX="$TARGETDIR_UNIX/$HOSTSRC_SUBDIR"
    OCAMLSRC_MIXED="$OCAMLSRC_UNIX"
fi

# Handle: -c OCAMLC_OPT_EXE
if [ -n "$OCAMLC_OPT_EXE" ]; then
    if [ -e "$OCAMLC_OPT_EXE" ]; then
        SETUP_ARGS+=( -c "$OCAMLC_OPT_EXE" )
        BUILD_HOST_ARGS+=( -c "$OCAMLC_OPT_EXE" )
    else
        OCAMLC_OPT_EXE=
    fi
fi

# Set BUILDHOST_ARCH
autodetect_buildhost_arch

# Add options that have defaults
if [ -z "$DKMLHOSTABI" ]; then
    DKMLHOSTABI="$BUILDHOST_ARCH"
fi
SETUP_ARGS+=( -b "'$MSVS_PREFERENCE'" -e "$DKMLHOSTABI" )
BUILD_HOST_ARGS+=( -b "'$MSVS_PREFERENCE'" -e "$DKMLHOSTABI" )
BUILD_CROSS_ARGS+=( -e "$DKMLHOSTABI" )

# ---------------------

# Prereqs for r-c-ocaml-functions.sh
autodetect_system_binaries
autodetect_system_path
autodetect_cpus
autodetect_posix_shell
export_safe_tmpdir

# shellcheck disable=SC1091
. "$DKMLDIR/vendor/dkml-compiler/src/r-c-ocaml-functions.sh"

compiler_clear_environment

# ---------------------
# Patching functions

# Sets the array VERSION_STEMS
#   Stems must be underscores since they are separated by dashes
set_ocaml_version_stems() {
    set_version_stems_VER=$1
    shift
    VERSION_STEMS=()
    case "$set_version_stems_VER" in
        4.*) VERSION_STEMS+=("4") ;;
        5.*) VERSION_STEMS+=("5") ;;
        *)
            echo "FATAL: Unsupported stemming case 1 for version $set_version_stems_VER" >&2
            exit 123
            ;;
    esac
    case "$set_version_stems_VER" in
        4.11.*) VERSION_STEMS+=("4_11") ;;
        4.12.*) VERSION_STEMS+=("4_12") ;;
        4.13.*) VERSION_STEMS+=("4_13") ;;
        4.14.*) VERSION_STEMS+=("4_14") ;;
        5.00.*) VERSION_STEMS+=("5_00") ;;
        5.01.*) VERSION_STEMS+=("5_01") ;;
        5.1.*) VERSION_STEMS+=("5_1") ;;
        5.2.*) VERSION_STEMS+=("5_2") ;;
        *)
            echo "FATAL: Unsupported stemming case 2 for version $set_version_stems_VER" >&2
            exit 123
            ;;
    esac
    case "$set_version_stems_VER" in
        4.14.0) VERSION_STEMS+=("4_14_0") ;;
        4.14.1) VERSION_STEMS+=("4_14_1") ;;
        4.14.2) VERSION_STEMS+=("4_14_2") ;;
        *)
            echo "FATAL: Unsupported stemming case 3 for version $set_version_stems_VER" >&2
            exit 123
            ;;
    esac
}
set_flexdll_version_stems() {
    set_version_stems_VER=$1
    shift
    VERSION_STEMS=()
    case "$set_version_stems_VER" in
        0.*) VERSION_STEMS+=("0") ;;
    esac
    case "$set_version_stems_VER" in
        0.39) VERSION_STEMS+=("0_39") ;;
    esac
    case "$set_version_stems_VER" in
        0.42) VERSION_STEMS+=("0_42") ;;
    esac
}
# Sets the array PATCHES and accumulates dkmldir/ relative paths, including
# any Markdown .md files, in array ALL_PATCH_FILES.
ALL_PATCH_FILES=()
set_patches() {
    set_patches_CATEGORY=$1
    shift
    set_patches_VER=$1
    shift
    set_patches_HOSTCROSS=$1
    shift

    # Set VERSION_STEMS
    case "$set_patches_CATEGORY" in
        ocaml)   set_ocaml_version_stems "$set_patches_VER";;
        flexdll) set_flexdll_version_stems "$set_patches_VER";;
        *) printf "FATAL: No category %s\n" "$set_patches_CATEGORY" >&2; exit 107
    esac

    PATCHES=()
    for set_patches_STEM in "${VERSION_STEMS[@]}"; do
        # Find, sort and accumulate common patches that belong to the stem.
        find "vendor/dkml-compiler/src/p" -type f -name "$set_patches_CATEGORY-common-$set_patches_STEM-*.patch" | LC_ALL=C sort > "$WORK/p"
        while IFS= read -r line; do
            PATCHES+=("$DKMLDIR/$line")
            ALL_PATCH_FILES+=("$line")
        done < "$WORK/p"
        #   Markdown
        find "vendor/dkml-compiler/src/p" -type f -name "$set_patches_CATEGORY-common-$set_patches_STEM-*.md" | LC_ALL=C sort > "$WORK/p"
        while IFS= read -r line; do
            ALL_PATCH_FILES+=("$line")
        done < "$WORK/p"
        # Find, sort and accumulate host/cross patches that belong to the stem.
        find "vendor/dkml-compiler/src/p" -type f -name "$set_patches_CATEGORY-$set_patches_HOSTCROSS-$set_patches_STEM-*.patch" | LC_ALL=C sort > "$WORK/p"
        while IFS= read -r line; do
            PATCHES+=("$DKMLDIR/$line")
            ALL_PATCH_FILES+=("$line")
        done < "$WORK/p"
        #   Markdown
        find "vendor/dkml-compiler/src/p" -type f -name "$set_patches_CATEGORY-$set_patches_HOSTCROSS-$set_patches_STEM-*.md" | LC_ALL=C sort > "$WORK/p"
        while IFS= read -r line; do
            ALL_PATCH_FILES+=("$line")
        done < "$WORK/p"
    done
}

apply_patch() {
    apply_patch_PATCHFILE=$1
    shift
    apply_patch_SRCDIR=$1
    shift
    apply_patch_CATEGORY=$1
    shift
    apply_patch_HOSTCROSS=$1
    shift

    apply_patch_PATCHBASENAME=$(basename "$apply_patch_PATCHFILE")
    apply_patch_SRCDIR_MIXED="$apply_patch_SRCDIR"
    apply_patch_PATCHFILE_MIXED="$apply_patch_PATCHFILE"
    if [ -x /usr/bin/cygpath ]; then
        apply_patch_SRCDIR_MIXED=$(/usr/bin/cygpath -aw "$apply_patch_SRCDIR_MIXED")
        apply_patch_PATCHFILE_MIXED=$(/usr/bin/cygpath -aw "$apply_patch_PATCHFILE_MIXED")
    fi
    # Before packaging any of these artifacts the CI will likely do a `git clean -d -f -x` to reduce the
    # size and increase the safety of the artifacts. So we do a `git commit` after we have patched so
    # the reproducible source code has the patches applied, even after the `git clean`.
    # log_trace git -C "$apply_patch_SRCDIR_MIXED" apply --verbose "$apply_patch_PATCHFILE_MIXED"
    log_trace git -C "$apply_patch_SRCDIR_MIXED" config user.email "nobody+autopatcher@diskuv.ocaml.org"
    log_trace git -C "$apply_patch_SRCDIR_MIXED" config user.name  "Auto Patcher"
    git -C "$apply_patch_SRCDIR_MIXED" am --abort 2>/dev/null || true # clean any previous interrupted mail patch
    {
        printf "From: nobody+autopatcher@diskuv.ocaml.org\n"
        printf "Subject: Diskuv %s %s patch %s\n" "$apply_patch_CATEGORY" "$apply_patch_HOSTCROSS" "$apply_patch_PATCHBASENAME"
        printf "Date: 1 Jan 2000 00:00:00 +0000\n"
        printf "\n"
        printf "Reproducible patch\n"
        printf "\n"
        printf "%s\n" "---"
        $DKMLSYS_CAT "$apply_patch_PATCHFILE_MIXED"
    } > "$WORK/current-patch"
    #cp "$WORK/current-patch" $DKMLDIR/
    log_trace git -C "$apply_patch_SRCDIR_MIXED" am --ignore-date --committer-date-is-author-date < "$WORK/current-patch"
}

apply_patches() {
    apply_patches_SRCDIR=$1
    shift
    apply_patches_CATEGORY=$1
    shift
    apply_patches_VER=$1
    shift
    apply_patches_HOSTCROSS=$1
    shift

    set_patches "$apply_patches_CATEGORY" "$apply_patches_VER" "$apply_patches_HOSTCROSS"
    set +u # Fix bash bug with empty arrays
    echo "patches($apply_patches_CATEGORY $apply_patches_HOSTCROSS) = ${PATCHES[*]}" >&2
    for patchfile in "${PATCHES[@]}"; do
        apply_patch "$patchfile" "$apply_patches_SRCDIR" "$apply_patches_CATEGORY" "$apply_patches_HOSTCROSS"
    done
    set -u
}

# ---------------------
# Get OCaml source code

# Set BUILDHOST_ARCH
autodetect_buildhost_arch

clean_ocaml_install() {
    clean_ocaml_install_DIR=$1
    shift
    # This can be a clean install for an upgrade of an existing OCaml installation;
    # that means we can't just blow away entire directories unless we know for
    # sure it is specific to OCaml
    for binary in "${BINARIES[@]}"; do
        log_trace rm -f "${clean_ocaml_install_DIR:?}/bin/$binary.exe"
        log_trace rm -f "${clean_ocaml_install_DIR:?}/bin/$binary"
    done
    log_trace rm -rf "${clean_ocaml_install_DIR:?}/lib/ocaml"
}

# [is_git_corrupt_or_missing <source code mixed Unix/Dos path>]
#
# Yes, [.git] can be corrupt if aborted during an operation. Ex.:
#       git status >>> fatal: bad object HEAD
#       git stash >>> BUG: diff-lib.c:612: run_diff_index must be passed exactly one tree
is_git_corrupt_or_missing() {
    is_git_present_but_corrupt_DIR=$1
    shift
    if [ ! -d "$is_git_present_but_corrupt_DIR/.git" ]; then
        return 0 # true. missing
    fi
    if log_trace --return-error-code git -C "$is_git_present_but_corrupt_DIR" fsck --strict --no-dangling --no-progress; then
        return 1 # false. valid
    fi
    return 0 # true
}

# Make a directory git patchable if it is not a git repository already
gitize() {
    gitize_DIR=$1
    shift

    if [ -e "$gitize_DIR/.git" ]; then
        return
    fi

    log_trace git -C "$gitize_DIR" -c init.defaultBranch=main init
    log_trace git -C "$gitize_DIR" config user.email "nobody+autocommitter@diskuv.ocaml.org"
    log_trace git -C "$gitize_DIR" config user.name  "Auto Committer"
    log_trace git -C "$gitize_DIR" config core.safecrlf false
    log_trace git -C "$gitize_DIR" config core.fsmonitor false # unneeded, and avoid "error: daemon terminated"
    log_trace git -C "$gitize_DIR" add -A
    log_trace git -C "$gitize_DIR" commit --quiet -m "Commit from source tree"
    log_trace git -C "$gitize_DIR" tag r-c-ocaml-1-setup-srctree
}

get_ocaml_source() {
    get_ocaml_source_COMMIT_TAG_OR_DIR=$1
    shift
    get_ocaml_source_SRCUNIX="$1"
    shift
    get_ocaml_source_SRCMIXED="$1"
    shift
    get_ocaml_source_TARGETPLATFORM="$1"
    shift

    # Get the unpatched ocaml/ocaml source code ...

    if [ -d "$get_ocaml_source_COMMIT_TAG_OR_DIR" ]; then
        # If there is a directory of the source code, use that.

        # Want idempotency, so remove source code if not present, or git is missing (that means
        # we have no idea whether commits have been applied) or git is corrupt
        if [ ! -e "$get_ocaml_source_SRCUNIX/Makefile" ] || is_git_corrupt_or_missing "$get_ocaml_source_SRCMIXED"; then
            log_trace install -d "$get_ocaml_source_SRCUNIX"
            log_trace rm -rf "$get_ocaml_source_SRCUNIX" # clean any partial downloads
            log_trace cp -rp "$get_ocaml_source_COMMIT_TAG_OR_DIR" "$get_ocaml_source_SRCUNIX"
            #   we do not want complicated submodules for a local directory copy
            log_trace rm -f "$get_ocaml_source_SRCUNIX/.gitmodules" "$get_ocaml_source_SRCUNIX/flexdll/.git"
        fi

        # Ensure git patchable
        gitize "$get_ocaml_source_SRCMIXED"

        # Move the repository to the expected tag
        log_trace git -C "$get_ocaml_source_SRCMIXED" stash
        log_trace git -C "$get_ocaml_source_SRCMIXED" -c advice.detachedHead=false checkout r-c-ocaml-1-setup-srctree
        log_trace git -C "$get_ocaml_source_SRCMIXED" reset --hard r-c-ocaml-1-setup-srctree
    else
        # Otherwise do git checkout / git fetch ...

        get_ocaml_source_COMMIT=$get_ocaml_source_COMMIT_TAG_OR_DIR

        if [ ! -e "$get_ocaml_source_SRCUNIX/Makefile" ] || is_git_corrupt_or_missing "$get_ocaml_source_SRCMIXED"; then
            log_trace rm -rf "$get_ocaml_source_SRCUNIX" # clean any partial downloads
            # do NOT --recurse-submodules because we don't want submodules (ex. flexdll/) that are in HEAD but
            # are not in $get_ocaml_source_COMMIT
            log_trace install -d "$get_ocaml_source_SRCUNIX"
            #   Instead of git clone we use git fetch --depth 1 so we do a shallow clone of the commit
            log_trace git -C "$get_ocaml_source_SRCMIXED" -c init.defaultBranch=master init
            log_trace git -C "$get_ocaml_source_SRCMIXED" config core.fsmonitor false # unneeded, and avoid "error: daemon terminated"
            log_trace git -C "$get_ocaml_source_SRCMIXED" remote add origin https://github.com/ocaml/ocaml
            log_trace git -C "$get_ocaml_source_SRCMIXED" fetch --depth 1 origin "$get_ocaml_source_COMMIT"
            log_trace git -C "$get_ocaml_source_SRCMIXED" reset --hard FETCH_HEAD
        else
            # Move the repository to the expected commit
            #
            #   Git fetch can be very expensive after a shallow clone; we skip advancing the repository
            #   if the expected tag/commit is a commit and the actual git commit is the expected git commit
            git_head=$(log_trace git -C "$get_ocaml_source_SRCMIXED" rev-parse HEAD)
            log_trace git -C "$get_ocaml_source_SRCMIXED" stash
            if [ ! "$git_head" = "$get_ocaml_source_COMMIT" ]; then
                # allow tag to move (for development and for emergency fixes), if the user chose a tag rather than a commit
                if git -C "$get_ocaml_source_SRCMIXED" tag -l "$get_ocaml_source_COMMIT" | awk 'BEGIN{nonempty=0} NF>0{nonempty+=1} END{exit nonempty==0}'; then git -C "$get_ocaml_source_SRCMIXED" tag -d "$get_ocaml_source_COMMIT"; fi

                log_trace git -C "$get_ocaml_source_SRCMIXED" fetch --tags
                log_trace git -C "$get_ocaml_source_SRCMIXED" -c advice.detachedHead=false checkout "$get_ocaml_source_COMMIT"
            fi
            log_trace git -C "$get_ocaml_source_SRCMIXED" reset --hard "$get_ocaml_source_COMMIT"
        fi
        log_trace git -C "$get_ocaml_source_SRCMIXED" submodule update --init --recursive

        # Remove any chmods we did in the previous build
        log_trace "$DKMLSYS_CHMOD" -R u+w "$get_ocaml_source_SRCMIXED"

        # OCaml compilation is _not_ idempotent. Example:
        #     config.status: creating Makefile.build_config
        #     config.status: creating Makefile.config
        #     config.status: creating tools/eventlog_metadata
        #     config.status: creating runtime/caml/m.h
        #     config.status: runtime/caml/m.h is unchanged
        #     config.status: creating runtime/caml/s.h
        #     config.status: runtime/caml/s.h is unchanged
        #     config.status: executing libtool commands
        #
        #     + env --unset=LIB --unset=INCLUDE --unset=PATH --unset=Lib --unset=Include --unset=Path PATH=/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/Common7/IDE/Extensions/Microsoft/IntelliCode/CLI:/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Tools/MSVC/14.26.28801/bin/HostX64/x64:/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/Common7/IDE/VC/VCPackages:/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/Common7/IDE/CommonExtensions/Microsoft/TestWindow:/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/Common7/IDE/CommonExtensions/Microsoft/TeamFoundation/Team Explorer:/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/MSBuild/Current/bin/Roslyn:/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/Team Tools/Performance Tools/x64:/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/Team Tools/Performance Tools:/c/Program Files (x86)/Microsoft Visual Studio/Shared/Common/VSPerfCollectionTools/vs2019/x64:/c/Program Files (x86)/Microsoft Visual Studio/Shared/Common/VSPerfCollectionTools/vs2019/:/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/Common7/Tools/devinit:/c/Program Files (x86)/Windows Kits/10/bin/10.0.18362.0/x64:/c/Program Files (x86)/Windows Kits/10/bin/x64:/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/MSBuild/Current/Bin:/c/Windows/Microsoft.NET/Framework64/v4.0.30319:/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/Common7/IDE/:/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/Common7/Tools/:/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin:/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/Common7/IDE/CommonExtensions/Microsoft/CMake/Ninja:/z/source/.../windows_x86_64/Debug/dksdk/ocaml/bin:/c/Users/beckf/AppData/Local/Programs/DiskuvOCaml/1/bin:/c/Program Files/Git/cmd:/usr/bin:/c/Windows/System32:/c/Windows:/c/Windows/System32/Wbem:/c/Windows/System32/WindowsPowerShell/v1.0:/c/Windows/System32/OpenSSH LIB=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.26.28801\lib\x64;C:\Program Files (x86)\Windows Kits\10\lib\10.0.18362.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\10\lib\10.0.18362.0\um\x64;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.26.28801\lib\x64;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.26.28801\atlmfc\lib\x64;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\VS\lib\x64;;C:\Program Files (x86)\Windows Kits\10\lib\10.0.18362.0\ucrt\x64;;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\VS\UnitTest\lib;C:\Program Files (x86)\Windows Kits\10\lib\10.0.18362.0\um\x64;lib\um\x64;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.26.28801\lib\x64;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.26.28801\atlmfc\lib\x64;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\VS\lib\x64;;C:\Program Files (x86)\Windows Kits\10\lib\10.0.18362.0\ucrt\x64;;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\VS\UnitTest\lib;C:\Program Files (x86)\Windows Kits\10\lib\10.0.18362.0\um\x64;lib\um\x64; INCLUDE=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.26.28801\include;C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\ucrt;C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\shared;C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um;C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\winrt;C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\cppwinrt;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.26.28801\include;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.26.28801\atlmfc\include;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\VS\include;;C:\Program Files (x86)\Windows Kits\10\Include\10.0.18362.0\ucrt;;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\VS\UnitTest\include;C:\Program Files (x86)\Windows Kits\10\Include\10.0.18362.0\um;C:\Program Files (x86)\Windows Kits\10\Include\10.0.18362.0\shared;C:\Program Files (x86)\Windows Kits\10\Include\10.0.18362.0\winrt;C:\Program Files (x86)\Windows Kits\10\Include\10.0.18362.0\cppwinrt;Include\um;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.26.28801\include;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.26.28801\atlmfc\include;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\VS\include;;C:\Program Files (x86)\Windows Kits\10\Include\10.0.18362.0\ucrt;;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\VS\UnitTest\include;C:\Program Files (x86)\Windows Kits\10\Include\10.0.18362.0\um;C:\Program Files (x86)\Windows Kits\10\Include\10.0.18362.0\shared;C:\Program Files (x86)\Windows Kits\10\Include\10.0.18362.0\winrt;C:\Program Files (x86)\Windows Kits\10\Include\10.0.18362.0\cppwinrt;Include\um; make flexdll
        #     make -C runtime BOOTSTRAPPING_FLEXLINK=yes ocamlrun.exe
        #     make[1]: Entering directory '/z/source/.../windows_x86_64/Debug/dksdk/ocaml/src/ocaml/runtime'
        #     cl -c -nologo -O2 -Gy- -MD    -D_CRT_SECURE_NO_DEPRECATE -DCAML_NAME_SPACE -DUNICODE -D_UNICODE -DWINDOWS_UNICODE=1 -DBOOTSTRAPPING_FLEXLINK -I"Z:\source\...\windows_x86_64\Debug\dksdk\ocaml\bin" -DCAMLDLLIMPORT= -DOCAML_STDLIB_DIR='L"Z:/source/.../windows_x86_64/Debug/dksdk/ocaml/lib/ocaml"'  -Fodynlink.b.obj dynlink.c
        #     dynlink.c
        #     link -lib -nologo -machine:AMD64  /out:libcamlrun.lib  interp.b.obj misc.b.obj stacks.b.obj fix_code.b.obj startup_aux.b.obj startup_byt.b.obj freelist.b.obj major_gc.b.obj minor_gc.b.obj memory.b.obj alloc.b.obj roots_byt.b.obj globroots.b.obj fail_byt.b.obj signals.b.obj signals_byt.b.obj printexc.b.obj backtrace_byt.b.obj backtrace.b.obj compare.b.obj ints.b.obj eventlog.b.obj floats.b.obj str.b.obj array.b.obj io.b.obj extern.b.obj intern.b.obj hash.b.obj sys.b.obj meta.b.obj parsing.b.obj gc_ctrl.b.obj md5.b.obj obj.b.obj lexing.b.obj callback.b.obj debugger.b.obj weak.b.obj compact.b.obj finalise.b.obj custom.b.obj dynlink.b.obj afl.b.obj win32.b.obj bigarray.b.obj main.b.obj memprof.b.obj domain.b.obj skiplist.b.obj codefrag.b.obj
        #     cl -nologo -O2 -Gy- -MD    -Feocamlrun.exe prims.obj libcamlrun.lib advapi32.lib ws2_32.lib version.lib  /link /subsystem:console /ENTRY:wmainCRTStartup && (test ! -f ocamlrun.exe.manifest || mt -nologo -outputresource:ocamlrun.exe -manifest ocamlrun.exe.manifest && rm -f ocamlrun.exe.manifest)
        #     libcamlrun.lib(win32.b.obj) : error LNK2019: unresolved external symbol flexdll_wdlopen referenced in function caml_dlopen
        #     libcamlrun.lib(win32.b.obj) : error LNK2019: unresolved external symbol flexdll_dlsym referenced in function caml_dlsym
        #     libcamlrun.lib(win32.b.obj) : error LNK2019: unresolved external symbol flexdll_dlclose referenced in function caml_dlclose
        #     libcamlrun.lib(win32.b.obj) : error LNK2019: unresolved external symbol flexdll_dlerror referenced in function caml_dlerror
        #     libcamlrun.lib(win32.b.obj) : error LNK2019: unresolved external symbol flexdll_dump_exports referenced in function caml_dlopen
        #     ocamlrun.exe : fatal error LNK1120: 5 unresolved externals
        # So clean directory every build
        log_trace git -C "$get_ocaml_source_SRCMIXED" clean -d -x -f
        log_trace git -C "$get_ocaml_source_SRCMIXED" submodule foreach --recursive "git clean -d -x -f -"
    fi

    # Install a synthetic msvs-detect if needed
    create_detect_msvs_script "$get_ocaml_source_TARGETPLATFORM" "$get_ocaml_source_SRCUNIX"/msvs-detect || true

    # Windows needs flexdll, although 4.13.x+ has a "--with-flexdll" option which relies on the `flexdll` git submodule
    if [ ! -e "$get_ocaml_source_SRCUNIX"/flexdll/Makefile ]; then
        log_trace downloadfile https://github.com/alainfrisch/flexdll/archive/0.39.tar.gz "$get_ocaml_source_SRCUNIX/flexdll.tar.gz" 51a6ef2e67ff475c33a76b3dc86401a0f286c9a3339ee8145053ea02d2fb5974
    fi
}

# Why multiple source directories?
# It is hard to reason about mutated source directories with different-platform object files, so we use a pristine source dir
# for the host and other pristine source dirs for each target.

clean_ocaml_install "$TARGETDIR_UNIX"
if [ -n "$TEMPLATEDIR" ]; then
    install -d "$OCAMLSRC_UNIX"
    rm -rf "$OCAMLSRC_UNIX"
    cp -rp "$TEMPLATEDIR/$HOSTSRC_SUBDIR" "$OCAMLSRC_UNIX"
else
    get_ocaml_source "$GIT_COMMITID_TAG_OR_DIR" "$OCAMLSRC_UNIX" "$OCAMLSRC_MIXED" "$BUILDHOST_ARCH"
fi

# Add get_sak.mk to runtime/
install vendor/dkml-compiler/src/r-c-ocaml-get_sak.make "$OCAMLSRC_UNIX"/runtime/get_sak.make

# Get source code versions from the source code
_OCAMLVER=$(awk 'NR==1{print}' "$OCAMLSRC_UNIX"/VERSION)
#   flexdll is only required for Windows; other OS-es can skip having it
if [ -e "$OCAMLSRC_UNIX"/flexdll/Makefile ]; then
    _FLEXDLLVER=$(awk '$1=="VERSION"{print $NF; exit 0}' "$OCAMLSRC_UNIX"/flexdll/Makefile)
fi

# Pass versions to build scripts
BUILD_HOST_ARGS+=( -s "$_OCAMLVER" )
BUILD_CROSS_ARGS+=( -s "$_OCAMLVER" )

# Find and apply patches to the host ABI
apply_patches "$OCAMLSRC_UNIX"          ocaml    "$_OCAMLVER"    host
if [ -e "$OCAMLSRC_UNIX"/flexdll/Makefile ] && is_unixy_windows_build_machine; then
    apply_patches "$OCAMLSRC_UNIX/flexdll"  flexdll  "$_FLEXDLLVER"  host
fi

if [ -z "$TARGETABIS" ]; then
    # Quick. Only support host builds.
    BUILD_HOST_ARGS+=( -q ON )
else
    if [ -n "$TEMPLATEDIR" ]; then
        install -d "$TARGETDIR_UNIX/$CROSS_SUBDIR"
        rm -rf "${TARGETDIR_UNIX:?}/$CROSS_SUBDIR"
        cp -rp "$TEMPLATEDIR/$CROSS_SUBDIR" "$TARGETDIR_UNIX/$CROSS_SUBDIR"
    else
        # Loop over each target abi script file; each file separated by semicolons, and each term with an equals
        printf "%s\n" "$TARGETABIS" | sed 's/;/\n/g' | sed 's/^\s*//; s/\s*$//' > "$WORK"/tabi
        while IFS= read -r _abientry
        do
            _targetabi=$(printf "%s" "$_abientry" | sed 's/=.*//')
            # clean install
            clean_ocaml_install "$TARGETDIR_UNIX/$CROSS_SUBDIR/$_targetabi"
            # git clone
            _srcabidir_unix="$TARGETDIR_UNIX/$CROSS_SUBDIR/$_targetabi/$HOSTSRC_SUBDIR"
            get_ocaml_source "$GIT_COMMITID_TAG_OR_DIR" "$_srcabidir_unix" "$TARGETDIR_MIXED/$CROSS_SUBDIR/$_targetabi/$HOSTSRC_SUBDIR" "$_targetabi"
            # Find and apply patches to the target ABI
            apply_patches "$_srcabidir_unix"            ocaml    "$_OCAMLVER"    cross
            if [ -e "$_srcabidir_unix"/flexdll/Makefile ] && is_unixy_windows_build_machine; then
                apply_patches "$_srcabidir_unix/flexdll"    flexdll  "$_FLEXDLLVER"  cross
            fi
        done < "$WORK"/tabi
    fi
fi

# ---------------------------
# Finish

# Copy self into share/dkml-bootstrap/100co (short form of 100-compile-ocaml
# so Windows and macOS paths are short)
export BOOTSTRAPNAME=100co
export DEPLOYDIR_UNIX="$TARGETDIR_UNIX"
DESTDIR=$TARGETDIR_UNIX/$SHARE_REPRODUCIBLE_BUILD_RELPATH/$BOOTSTRAPNAME
THISDIR=$(pwd)
if [ "$DESTDIR" = "$THISDIR" ]; then
    printf "Already deployed the reproducible scripts. Replacing them as needed\n"
    DKMLDIR=.
fi
# shellcheck disable=SC2016
COMMON_ARGS=(-d "$SHARE_REPRODUCIBLE_BUILD_RELPATH/$BOOTSTRAPNAME")
install_reproducible_common
install_reproducible_readme           vendor/dkml-compiler/src/r-c-ocaml-README.md
install_reproducible_file             vendor/dkml-compiler/src/r-c-ocaml-check_linker.sh
install_reproducible_file             vendor/dkml-compiler/src/r-c-ocaml-functions.sh
install_reproducible_file             vendor/dkml-compiler/src/r-c-ocaml-get_sak.make
if [ -n "$HOSTABISCRIPT" ]; then
    install_reproducible_file         "$HOSTABISCRIPT"
fi
if [ -n "$OCAMLC_OPT_EXE" ]; then
    install_reproducible_file         "$OCAMLC_OPT_EXE"
fi
for patchfile in "${ALL_PATCH_FILES[@]}"; do
    install_reproducible_file         "$patchfile"
done
if [ -n "$TARGETABIS" ]; then
    _accumulator=
    # Loop over each target abi script file; each file separated by semicolons, and each term with an equals
    printf "%s\n" "$TARGETABIS" | sed 's/;/\n/g' | sed 's/^\s*//; s/\s*$//' > "$WORK"/tabi
    while IFS= read -r _abientry
    do
        _targetabi=$(printf "%s" "$_abientry" | sed 's/=.*//')
        _abiscript=$(printf "%s" "$_abientry" | sed 's/^[^=]*=//')

        # Since we want the ABI scripts to be reproducible, we install them in a reproducible place and set
        # the reproducible arguments (-a) to point to that reproducible place.
        _script="vendor/dkml-compiler/src/r-c-ocaml-targetabi-$_targetabi.sh"
        if [ -n "$_accumulator" ]; then
            _accumulator="$_accumulator;$_targetabi=$_script"
        else
            _accumulator="$_targetabi=$_script"
        fi
        install_reproducible_generated_file "$_abiscript" vendor/dkml-compiler/src/r-c-ocaml-targetabi-"$_targetabi".sh
    done < "$WORK"/tabi
    SETUP_ARGS+=( -a "$_accumulator" )
    BUILD_CROSS_ARGS+=( -a "$_accumulator" )
fi
install_reproducible_system_packages  vendor/dkml-compiler/src/r-c-ocaml-0-system.sh
install_reproducible_script_with_args vendor/dkml-compiler/src/r-c-ocaml-1-setup.sh "${COMMON_ARGS[@]}" "${SETUP_ARGS[@]}"
install_reproducible_script_with_args vendor/dkml-compiler/src/r-c-ocaml-2-build_host.sh "${COMMON_ARGS[@]}" "${BUILD_HOST_ARGS[@]}"
install_reproducible_script_with_args vendor/dkml-compiler/src/r-c-ocaml-3-build_cross.sh "${COMMON_ARGS[@]}" "${BUILD_CROSS_ARGS[@]}"
install_reproducible_script_with_args vendor/dkml-compiler/src/r-c-ocaml-9-trim.sh "${COMMON_ARGS[@]}" "${TRIM_ARGS[@]}"

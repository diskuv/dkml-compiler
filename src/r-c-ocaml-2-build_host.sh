#!/bin/sh
#
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
######################################
# r-c-ocaml-2-build_host.sh -d DKMLDIR -t TARGETDIR
#
# Purpose:
# 1. Build an OCaml environment including an OCaml native compiler that generates machine code for the
#    host ABI. Much of that follows
#    https://github.com/ocaml/opam/blob/012103bc52bfd4543f3d6f59edde91ac70acebc8/shell/bootstrap-ocaml.sh,
#    especially the Windows knobs.
#
# -------------------------------------------------------
set -euf

# ------------------
# BEGIN Command line processing

usage() {
    {
        printf "%s\n" "Usage:"
        printf "%s\n" "    r-c-ocaml-2-build_host.sh"
        printf "%s\n" "        -h             Display this help message."
        printf "%s\n" "        -d DIR -t DIR  Compile OCaml."
        printf "\n"
        printf "%s\n" "See 'r-c-ocaml-1-setup.sh -h' for more comprehensive docs."
        printf "\n"
        printf "%s\n" "Options"
        printf "%s\n" "   -s OCAMLVER: The OCaml version"
        printf "%s\n" "   -d DIR: DKML directory containing a .dkmlroot file"
        printf "%s\n" "   -t DIR: Target directory for the reproducible directory tree"
        printf "%s\n" "   -b PREF: Required and used only for the MSVC compiler. See r-c-ocaml-1-setup.sh"
        printf "%s\n" "   -c OCAMLC_OPT_EXE: If a possibly older 'ocamlc.opt' is specified, it speeds up compilation of the new OCaml compiler"
        printf "%s\n" "   -e DKMLHOSTABI: Uses the DkML compiler detector find a host ABI compiler"
        printf "%s\n" "   -f HOSTSRC_SUBDIR: Use HOSTSRC_SUBDIR subdirectory of -t DIR to place the source code of the host ABI"
        printf "%s\n" "   -p HOST_SUBDIR: Optional. Use HOST_SUBDIR subdirectory of -t DIR to place the host ABI"
        printf "%s\n" "   -k HOSTABISCRIPT: Optional. See r-c-ocaml-1-setup.sh"
        printf "%s\n" "   -l FLEXLINKFLAGS: Options added to flexlink while building ocaml, ocamlc, etc. native Windows executables"
        printf "%s\n" "   -m CONFIGUREARGS: Optional. Extra arguments passed to OCaml's ./configure. --with-flexdll"
        printf "%s\n" "      and --host will have already been set appropriately, but you can override the --host heuristic by adding it"
        printf "%s\n" "      to -m CONFIGUREARGS. Can be repeated"
        printf "%s\n" "   -q [ON|OFF]: Optional. Defaults to OFF. Only support host builds, not cross-compiling. Much quicker"
        printf "%s\n" "   -r Only build ocamlrun, Stdlib and the other libraries. Cannot be used with -a TARGETABIS."
        printf "%s\n" "   -w Disable non-essentials like the native toplevel and ocamldoc."
    } >&2
}

_OCAMLVER=
DKMLDIR=
TARGETDIR=
DKMLHOSTABI=
CONFIGUREARGS=
HOSTABISCRIPT=
RUNTIMEONLY=OFF
HOSTSRC_SUBDIR=
HOST_SUBDIR=
HOST_ONLY=OFF
OCAMLC_OPT_EXE=
FLEXLINKFLAGS=
DISABLE_EXTRAS=0
export MSVS_PREFERENCE=
while getopts ":s:d:t:b:c:e:m:k:l:rf:p:q:wh" opt; do
    case ${opt} in
        h )
            usage
            exit 0
        ;;
        w ) DISABLE_EXTRAS=1 ;;
        s ) _OCAMLVER="$OPTARG" ;;
        d )
            DKMLDIR="$OPTARG"
            if [ ! -e "$DKMLDIR/.dkmlroot" ]; then
                printf "%s\n" "Expected a DKMLDIR at $DKMLDIR but no .dkmlroot found" >&2;
                usage
                exit 1
            fi
            DKMLDIR=$(cd "$DKMLDIR" && pwd) # absolute path
        ;;
        t )
            TARGETDIR="$OPTARG"
        ;;
        b )
            MSVS_PREFERENCE="$OPTARG"
        ;;
        e )
            DKMLHOSTABI="$OPTARG"
        ;;
        c ) OCAMLC_OPT_EXE="$OPTARG" ;;
        f ) HOSTSRC_SUBDIR=$OPTARG ;;
        p ) HOST_SUBDIR=$OPTARG ;;
        m )
            CONFIGUREARGS="$CONFIGUREARGS $OPTARG"
        ;;
        k)
            HOSTABISCRIPT="$OPTARG"
            ;;
        l ) FLEXLINKFLAGS="$OPTARG" ;;
        q ) HOST_ONLY="$OPTARG" ;;
        r)
            RUNTIMEONLY=ON
            ;;
        \? )
            printf "%s\n" "This is not an option: -$OPTARG" >&2
            usage
            exit 1
        ;;
    esac
done
shift $((OPTIND -1))

if [ -z "$_OCAMLVER" ] || [ -z "$DKMLDIR" ] || [ -z "$TARGETDIR" ] || [ -z "$DKMLHOSTABI" ] || [ -z "$HOSTSRC_SUBDIR" ]; then
    printf "%s\n" "Missing required options" >&2
    usage
    exit 1
fi

# Export to flexlink during build
export FLEXLINKFLAGS

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
TARGETDIR_UNIX=$(cd "$TARGETDIR" && pwd) # better than cygpath: handles TARGETDIR=. without trailing slash, and works on Unix/Windows
OCAMLHOST_UNIX="$TARGETDIR_UNIX/$HOST_SUBDIR"
if [ -x /usr/bin/cygpath ]; then
    OCAMLSRC_UNIX=$(/usr/bin/cygpath -au "$TARGETDIR_UNIX/$HOSTSRC_SUBDIR")
    OCAMLSRC_HOST=$(/usr/bin/cygpath -aw "$TARGETDIR_UNIX/$HOSTSRC_SUBDIR")
    # Makefiles have very poor support for Windows paths, so use mixed (ex. C:/Windows) paths
    OCAMLSRC_MIXED=$(/usr/bin/cygpath -am "$TARGETDIR_UNIX/$HOSTSRC_SUBDIR")
else
    OCAMLSRC_UNIX="$TARGETDIR_UNIX/$HOSTSRC_SUBDIR"
    OCAMLSRC_HOST="$TARGETDIR_UNIX/$HOSTSRC_SUBDIR"
    OCAMLSRC_MIXED="$TARGETDIR_UNIX/$HOSTSRC_SUBDIR"
fi
export OCAMLSRC_MIXED

# ------------------

# Prereqs for r-c-ocaml-functions.sh
autodetect_system_binaries
autodetect_system_path
autodetect_cpus
autodetect_posix_shell
export_safe_tmpdir

# shellcheck disable=SC1091
. "$DKMLDIR/vendor/dkml-compiler/src/r-c-ocaml-functions.sh"

compiler_clear_environment

if [ -n "$HOSTABISCRIPT" ]; then
    case "$HOSTABISCRIPT" in
    /* | ?:*) # /a/b/c or C:\Windows
    ;;
    *) # relative path; need absolute path since we will soon change dir to $OCAMLSRC_UNIX
    HOSTABISCRIPT="$DKMLDIR/$HOSTABISCRIPT"
    ;;
    esac
fi

if [ -n "$OCAMLC_OPT_EXE" ]; then
    case "$OCAMLC_OPT_EXE" in
    /* | ?:*) # /a/b/c or C:\Windows
    ;;
    *) # relative path; need absolute path since we will soon change dir to $OCAMLSRC_UNIX
    OCAMLC_OPT_EXE="$DKMLDIR/$OCAMLC_OPT_EXE"
    ;;
    esac
fi

cd "$OCAMLSRC_UNIX"

# Dump environment variables
if [ "${DKML_BUILD_TRACE:-OFF}" = ON ] && [ "${DKML_BUILD_TRACE_LEVEL:-0}" -ge 2 ] ; then
    printf '@+ build_host env\n' >&2
    "$DKMLSYS_ENV" | "$DKMLSYS_SED" 's/^/@env+| /' | "$DKMLSYS_AWK" '{print}' >&2
    printf '@env?| DKML_COMPILE_SPEC=%s\n' "${DKML_COMPILE_SPEC:-}" >&2
    printf '@env?| DKML_COMPILE_TYPE=%s\n' "${DKML_COMPILE_TYPE:-}" >&2
fi

# Make C compiler script for host ABI. Allow passthrough of C compiler from caller, otherwise
# use the system (SYS) compiler.
install -d "$OCAMLSRC_MIXED"/support
HOST_DKML_COMPILE_SPEC=${DKML_COMPILE_SPEC:-1}
HOST_DKML_COMPILE_TYPE=${DKML_COMPILE_TYPE:-SYS}
#   Exports OCAML_HOST_TRIPLET and DKML_TARGET_SYSROOT
DKML_TARGET_ABI="$DKMLHOSTABI" DKML_COMPILE_SPEC=$HOST_DKML_COMPILE_SPEC DKML_COMPILE_TYPE=$HOST_DKML_COMPILE_TYPE \
    autodetect_compiler \
    --post-transform "$HOSTABISCRIPT" \
    "$OCAMLSRC_MIXED"/support/with-host-c-compiler.sh
#   To save a lot of troubleshooting time, we'll dump details
$DKMLSYS_INSTALL -d "$OCAMLHOST_UNIX/share/dkml/detect"
$DKMLSYS_INSTALL "$HOSTABISCRIPT" "$OCAMLHOST_UNIX/share/dkml/detect/post-transform.sh"

# ./configure
# Output: OCAML_CONFIGURE_NEEDS_MAKE_FLEXDLL
if [ "$RUNTIMEONLY" = ON ]; then
    CONFIGUREARGS="$CONFIGUREARGS --disable-native-compiler --disable-stdlib-manpages --disable-ocamldoc"
else
    case "$DISABLE_EXTRAS,$_OCAMLVER" in
        0,4.14.*|0,5.*)
            # Install native toplevel
            CONFIGUREARGS="$CONFIGUREARGS --enable-native-toplevel"
            ;;
    esac
    if [ "$DISABLE_EXTRAS" -eq 1 ]; then
        CONFIGUREARGS="$CONFIGUREARGS --disable-ocamldoc"
    fi
fi
log_trace ocaml_configure "$OCAMLHOST_UNIX" "$DKMLHOSTABI" \
    "$OCAMLSRC_MIXED"/support/with-host-c-compiler.sh "$OCAML_HOST_TRIPLET" "$DKML_TARGET_SYSROOT" \
    "$CONFIGUREARGS"

# Skip bootstrapping if ocamlc.opt is present
if [ -n "$OCAMLC_OPT_EXE" ]; then
    case "$DKMLHOSTABI" in
        windows_*) log_trace install "$OCAMLC_OPT_EXE" boot/ocamlc.opt.exe ;;
        *)         log_trace install "$OCAMLC_OPT_EXE" boot/ocamlc.opt
    esac
fi

# Capture SAK_ variables for use in cross-compiler.
# We need $(1) and $(2) parameter placeholders to get passed as well, so
# we encode them.
log_trace ocaml_make "$DKMLHOSTABI" -C runtime -f get_sak.make sak.source.sh 1=__1__ 2=__2__
if [ "${DKML_BUILD_TRACE:-OFF}" = ON ] && [ "${DKML_BUILD_TRACE_LEVEL:-0}" -ge 2 ] ; then
    printf '@+ runtime/sak.source.sh\n' >&2
    cat runtime/sak.source.sh >&2
fi

# fix readonly perms we'll set later (if we've re-used the files because
# of a cache)
log_trace "$DKMLSYS_CHMOD" -R ug+w      stdlib/

# Make non-boot ./ocamlc and ./ocamlopt compiler
if [ "$OCAML_CONFIGURE_NEEDS_MAKE_FLEXDLL" = ON ]; then
    #   trigger `flexlink` target, especially its making of boot/ocamlrun.exe
    log_trace touch flexdll/Makefile
    log_trace rm -f flexdll/flexlink.exe
    log_trace ocaml_make "$DKMLHOSTABI" flexdll
fi
log_trace ocaml_make "$DKMLHOSTABI"     coldstart
log_trace ocaml_make "$DKMLHOSTABI"     coreall            # Also produces ./ocaml
log_trace install -d "$OCAMLHOST_UNIX/bin" "$OCAMLHOST_UNIX/lib/ocaml" "$OCAMLHOST_UNIX/lib/ocaml/stublibs"
if [ "$RUNTIMEONLY" = ON ]; then
    log_trace ocaml_make "$DKMLHOSTABI" -C runtime install
    log_trace ocaml_make "$DKMLHOSTABI" -C stdlib install
    log_trace ocaml_make "$DKMLHOSTABI" otherlibraries
    # shellcheck disable=SC2016
    OTHERLIBRARIES=$($DKMLSYS_AWK 'BEGIN{FS="="} $1=="OTHERLIBRARIES"{print $2}' Makefile.config)
    for otherlibrary in ${OTHERLIBRARIES}; do
        ocaml_make "$DKMLHOSTABI"       -C otherlibs/"$otherlibrary" install
    done
    # Finished the runtime parts
    exit 0
fi
log_trace ocaml_make "$DKMLHOSTABI" opt-core
log_trace ocaml_make "$DKMLHOSTABI" ocamlc.opt
#   Generated ./ocamlc for some reason has a shebang reference to the bin/ocamlrun install
#   location. So install the runtime.
log_trace ocaml_make "$DKMLHOSTABI"     -C runtime install
log_trace ocaml_make "$DKMLHOSTABI"     ocamlopt.opt       # Can use ./ocamlc (depends on exact sequence above; doesn't now though)

# Probe the artifacts from ./configure + ./ocamlc
init_hostvars

build_with_support_for_cross_compiling() {
    # Make script to set OCAML_FLEXLINK so flexlink.exe and run correctly on Windows, and other
    # environment variables needed to link OCaml bytecode or native code on the host.
    #
    #   We have a bad flexlink situation on Windows. flexlink.exe will either be a
    #   native executable or a bytecode executable; when it is a native executable
    #   it will segfault if it is not installed in the right file location (you
    #   can't run it from flexdll/flexlink.exe); when it is a bytecode executable
    #   you need to run it with ocamlrun (unlike Unix which interpret the
    #   shebang to ocamlrun).
    #   So on Windows ...
    #   1. We consistently use the ocamlrun bytecode form of flexlink.exe
    #   2. We only make the native code flexlink.exe as the very last step (when
    #      it can't be used for linking other executables)
    if [ "$OCAML_CONFIGURE_NEEDS_MAKE_FLEXDLL" = ON ]; then
        # OCAML_FLEXLINK is expected to be a bytecode executable

        #   Since OCAML_FLEXLINK does not support spaces like in
        #   C:\Users\John Doe\flexdll
        #   we make a single script for `*/boot/ocamlrun */flexdll/flexlink.exe`
        {
            printf "#!%s\n" "$DKML_POSIX_SHELL"
            if [ "${DKML_BUILD_TRACE:-OFF}" = ON ] && [ "${DKML_BUILD_TRACE_LEVEL:-0}" -ge 4 ] ; then
                printf "exec '%s/boot/ocamlrun' '%s' -v -v \"\$@\"\n" "$OCAMLSRC_UNIX" "$OCAMLSRC_HOST"'\flexdll\flexlink.exe'
            elif [ "${DKML_BUILD_TRACE:-OFF}" = ON ] && [ "${DKML_BUILD_TRACE_LEVEL:-0}" -ge 2 ] ; then
                printf "exec '%s/boot/ocamlrun' '%s' -v \"\$@\"\n" "$OCAMLSRC_UNIX" "$OCAMLSRC_HOST"'\flexdll\flexlink.exe'
            else
                printf "exec '%s/boot/ocamlrun' '%s' \"\$@\"\n" "$OCAMLSRC_UNIX" "$OCAMLSRC_HOST"'\flexdll\flexlink.exe'
            fi
        } >"$OCAMLSRC_UNIX"/support/ocamlrun-flexlink.sh.tmp
        $DKMLSYS_CHMOD +x "$OCAMLSRC_UNIX"/support/ocamlrun-flexlink.sh.tmp
        $DKMLSYS_MV "$OCAMLSRC_UNIX"/support/ocamlrun-flexlink.sh.tmp "$OCAMLSRC_UNIX"/support/ocamlrun-flexlink.sh
        log_script "$OCAMLSRC_UNIX"/support/ocamlrun-flexlink.sh

        #   Then we call it using env.exe since ocamlrun-flexlink.sh can be called from
        #   a Command Prompt context.
        {
            printf "#!%s\n" "$DKML_POSIX_SHELL"
            printf "export OCAML_FLEXLINK='%s %s/support/ocamlrun-flexlink.sh'\n" "$HOST_SPACELESS_ENV_MIXED_EXE" "$OCAMLSRC_MIXED"
            printf "exec \"\$@\"\n"
        } >"$OCAMLSRC_UNIX"/support/with-linking-on-host.sh.tmp
    else
        printf "#!%s\nexec \"\$@\"\n" "$DKML_POSIX_SHELL" >"$OCAMLSRC_UNIX"/support/with-linking-on-host.sh.tmp
    fi
    $DKMLSYS_CHMOD +x "$OCAMLSRC_UNIX"/support/with-linking-on-host.sh.tmp
    $DKMLSYS_MV "$OCAMLSRC_UNIX"/support/with-linking-on-host.sh.tmp "$OCAMLSRC_UNIX"/support/with-linking-on-host.sh
    log_script "$OCAMLSRC_UNIX"/support/with-linking-on-host.sh

    # Host wrappers
    #   Technically the wrappers are not needed. However, the cross-compiling part needs to have the exact same host compiler
    #   settings we use here, so the wrappers are what we want. Actually, just let the cross compiling part re-use the same
    #   host wrapper.
    create_ocamlc_wrapper() {
        create_ocamlc_wrapper_PASS=$1 ; shift
        # shellcheck disable=SC2086
        log_trace genWrapper "$OCAMLSRC_MIXED/support/ocamlcHost$create_ocamlc_wrapper_PASS.wrapper"     "$OCAMLSRC_MIXED"/support/with-host-c-compiler.sh "$OCAMLSRC_MIXED"/support/with-linking-on-host.sh "$OCAMLSRC_MIXED/ocamlc.opt$HOST_EXE_EXT" "$@"
    }
    create_ocamlopt_wrapper() {
        create_ocamlopt_wrapper_PASS=$1 ; shift
        # shellcheck disable=SC2086
        log_trace genWrapper "$OCAMLSRC_MIXED/support/ocamloptHost$create_ocamlopt_wrapper_PASS.wrapper" "$OCAMLSRC_MIXED"/support/with-host-c-compiler.sh "$OCAMLSRC_MIXED"/support/with-linking-on-host.sh "$OCAMLSRC_MIXED/ocamlopt.opt$HOST_EXE_EXT" "$@"
    }
    create_ocamlrun_ocamlopt_wrapper() {
        create_ocamlrun_ocamlopt_wrapper_PASS=$1 ; shift
        # shellcheck disable=SC2086
        log_trace genWrapper "$OCAMLSRC_MIXED/support/ocamloptHost$create_ocamlrun_ocamlopt_wrapper_PASS.wrapper" "$OCAMLSRC_MIXED"/support/with-host-c-compiler.sh "$OCAMLSRC_MIXED"/support/with-linking-on-host.sh "$OCAMLSRC_MIXED/runtime/ocamlrun$HOST_EXE_EXT" "$OCAMLSRC_MIXED/ocamlopt$HOST_EXE_EXT" "$@"
    }
    #   Since the Makefile is sensitive to timestamps, we must make sure the wrappers have timestamps
    #   before any generated code (or else it will recompile).
    create_ocamlc_wrapper               -compile-stdlib
    create_ocamlopt_wrapper             -compile-stdlib
    case "$DKMLHOSTABI" in
        windows_*)
            _unix_include="$OCAMLSRC_MIXED${HOST_DIRSEP}otherlibs${HOST_DIRSEP}win32unix"
            ;;
        *)
            _unix_include="$OCAMLSRC_MIXED${HOST_DIRSEP}otherlibs${HOST_DIRSEP}unix"
            ;;
    esac
    create_ocamlc_wrapper               -compile-ocamlopt   -I "$OCAMLSRC_MIXED${HOST_DIRSEP}stdlib" -I "$_unix_include" -nostdlib
    create_ocamlrun_ocamlopt_wrapper    -compile-ocamlopt   -I "$OCAMLSRC_MIXED${HOST_DIRSEP}stdlib" -I "$_unix_include" -nostdlib
    create_ocamlc_wrapper               -final              -I "$OCAMLSRC_MIXED${HOST_DIRSEP}stdlib" -I "$_unix_include" -nostdlib
    create_ocamlopt_wrapper             -final              -I "$OCAMLSRC_MIXED${HOST_DIRSEP}stdlib" -I "$_unix_include" -nostdlib

    # Remove all OCaml compiled modules since they were compiled with boot/ocamlc
    #   We do not want _any_ `make inconsistent assumptions over interface Stdlib__format` during cross-compilation.
    #   Technically if all we wanted was the host OCaml system, we don't need to remove all OCaml compiled modules; its `make world` has that intelligence.
    #   Exclude the testsuite which has checked-in .cmm files, and exclude .cmd files.
    remove_compiled_objects_from_curdir

    # Recompile stdlib (and flexdll if enabled)
    printf "+ INFO: Compiling stdlib in pass 1\n" >&2
    log_trace make_host -compile-stdlib     -C stdlib all
    log_trace make_host -compile-stdlib     -C stdlib allopt
    #   Any future Makefile target that uses ./ocamlc will try to recompile it because it depends
    #   on compilerlibs/ocamlcommon.cma (and other .cma files). And that will trigger a new
    #   recompilation of stdlib. So we have to recompile them both until no more surprise
    #   recompilations of stdlib (creating `make inconsistent assumptions`).
    printf "+ INFO: Recompiling ocamlc in pass 1\n" >&2
    log_trace make_host -final              ocamlc
    printf "+ INFO: Recompiling ocamlopt in pass 1\n" >&2
    log_trace make_host -final              ocamlopt
    printf "+ INFO: Recompiling ocamlc.opt in pass 1\n" >&2
    log_trace make_host -final              ocamlc.opt
    printf "+ INFO: Recompiling ocamlopt.opt in pass 1\n" >&2
    #   Since `make_host -final` uses ocamlopt.opt we should not (and cannot on Windows)
    #   overwrite the executable which is producing the executable (even if it works on some OS).
    #   So run the bytecode ocamlopt executable to produce the native code ocamlopt.opt
    log_trace make_host -compile-ocamlopt    ocamlopt.opt
    printf "+ INFO: Recompiling stdlib in pass 2\n" >&2
    log_trace make_host -compile-stdlib     -C stdlib all
    log_trace make_host -compile-stdlib     -C stdlib allopt
    #   Bad things will happen if a subsequent make target like `all` recompiles
    #   stdlib. Stdlib should be 100% stabilized at this point. If it is not
    #   stabilized, we will get `make inconsistent assumptions` later and it
    #   will be tricky to understand where they are coming from.
    #
    #   Mitigation: Changing permissions to 500 (rx-------) will hopefully cause
    #   Permission Denied immediately at exact location where stdlib is being
    #   rebuilt. If we've done our job right in this section, stdlib will not
    #   be rebuilt at all.
    log_trace "$DKMLSYS_CHMOD" -R 500       stdlib/

    # Use new compiler to rebuild, with the exact same wrapper that can be used if cross-compiling
    if [ "${DKML_BUILD_TRACE:-OFF}" = ON ] && [ "${DKML_BUILD_TRACE_LEVEL:-0}" -ge 3 ] ; then
        # The `make -d` debug option will show the reason why stdlib (or anything else)
        # is being rebuilt.
        log_trace make_host -final          all -d
    else
        log_trace make_host -final          all
    fi
    log_trace make_host -final              "${BOOTSTRAP_OPT_TARGET:-opt.opt}"

    # flexlink.opt _must_ be the last thing built. See discussion near the
    # beginning about "bad flexlink situation on Windows".
    if [ "${OCAML_BYTECODE_ONLY:-OFF}" = OFF ] && [ "$OCAML_CONFIGURE_NEEDS_MAKE_FLEXDLL" = ON ]; then
        log_trace ocaml_make "$DKMLHOSTABI" flexlink.opt
    fi

    # Restore file permissions
    log_trace "$DKMLSYS_CHMOD" -R ug+w      stdlib/

    # Install
    log_trace make_host -final              install
}
build_for_host_only() {
    log_trace ocaml_make "$DKMLHOSTABI" all
    log_trace ocaml_make "$DKMLHOSTABI" "${BOOTSTRAP_OPT_TARGET:-opt.opt}"
    log_trace ocaml_make "$DKMLHOSTABI" install
}

# Do expensive support for cross-compiling, or do a host-only build
if [ "$HOST_ONLY" = OFF ]; then
    build_with_support_for_cross_compiling
else
    build_for_host_only
fi

# Flexlink constants
FLEXLINK_CHAIN=
FLEXLINK_EXT=
case "$DKMLHOSTABI" in
    windows_x86_64) FLEXLINK_CHAIN=msvc64; FLEXLINK_EXT=.obj ;;
    windows_x86)    FLEXLINK_CHAIN=msvc  ; FLEXLINK_EXT=.obj ;;
esac

# Windows errata
# 1. <OCAMLHOME>/bin/flexlink.exe expects flexdll_initer_msvc[64].obj and
#    flexdll_msvc[64].obj in the same directory as flexlink.exe, or else
#    FLEXDIR environment variable needs to be set.
#    It is in the build directory boot/.
#    Confer: https://github.com/ocaml/flexdll/blob/f5ccd9730d0766d0eb002cbe35a183f627044291/reloc.ml#L1407-L1428
if [ "${OCAML_BYTECODE_ONLY:-OFF}" = OFF ] && [ -n "$FLEXLINK_CHAIN" ]; then
    log_trace install "boot/flexdll_initer_${FLEXLINK_CHAIN}${FLEXLINK_EXT}"   "$OCAMLHOST_UNIX"/bin/
    log_trace install "boot/flexdll_${FLEXLINK_CHAIN}${FLEXLINK_EXT}"          "$OCAMLHOST_UNIX"/bin/
fi

# Test executables that they were properly linked
if [ "${OCAML_BYTECODE_ONLY:-OFF}" = OFF ] && [ -n "$FLEXLINK_CHAIN" ]; then
    log_trace "$OCAMLHOST_UNIX"/bin/flexlink.exe --help >&2
fi
log_trace "$OCAMLHOST_UNIX"/bin/ocamlc -config >&2
log_trace "$OCAMLHOST_UNIX"/bin/ocamlopt -config >&2
log_trace "$OCAMLHOST_UNIX"/bin/ocamlc.opt -config >&2
log_trace "$OCAMLHOST_UNIX"/bin/ocamlopt.opt -config >&2

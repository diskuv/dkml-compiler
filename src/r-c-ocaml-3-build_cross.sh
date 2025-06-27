#!/bin/sh
#
# This file has parts that are governed by one license and other parts that are governed by a second license (both apply).
# The first license is:
#   Licensed under https://github.com/EduardoRFS/reason-mobile/blob/7ba258319b87943d2eb0d8fb84562d0afeb2d41f/LICENSE#L1 - MIT License
# The second license (Apache License, Version 2.0) is below.
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
# @jonahbeckford: 2021-10-26
# - This file is licensed differently than the rest of the DkML distribution.
#   Keep the Apache License in this file since this file is part of the reproducible
#   build files.
#
######################################
# r-c-ocaml-3-build_cross.sh -d DKMLDIR -t TARGETDIR
#
# Purpose:
# 1. Optional layer on top of a host OCaml environment a cross-compiling OCaml environment using techniques pioneered by
#    @EduardoRFS:
#    a) the OCaml native libraries use the target ABI
#    b) the OCaml native compiler generates the target ABI
#    c) the OCaml compiler-library package uses the target ABI and generate the target ABI
#    d) the remainder (especially the OCaml toplevel) use the host ABI
#    See https://github.com/anmonteiro/nix-overlays/blob/79d36ea351edbaf6ee146d9bf46b09ee24ed6ece/cross/ocaml.nix for
#    reference material and an alternate way of doing it on nix.
#
######################################
#
# The generated findlib configuration file will be
# <PREFIX_DIR>/lib/findlib.conf.d/<toolchain>.conf for compatibility
# with Dune's `dune -x` option. The generation is mostly idempotent
# since, if the file already exsts, entries are only added to FINDLIB_CONF.
#
# MLCROSS_DIR is the base directory for zero or more target DKML ABIs (ex.
# android_arm32v7a) that contains bin/ and lib/ subfolders (ex.
# android_arm32v7a/bin). It can be an environment variable, but a default value
# must still be specified on the command line.
#
# findlib.conf on output
# ----------------------
#
# path(<dkmlabi>) = "<MLCROSS_DIR>/<dkmlabi>/lib:<PREFIX_DIR>/<dkmlabi>-sysroot/lib"
#   The META/package search path will start in the cross-compiled lib folder.
#   There are no META packages in the cross-compiled folder today, but that may change.
#   Opam installs packages into <PREFIX_DIR>/<dkmlabi>-sysroot/; precisely `dune -x`
#   creates a <package>.install file containing that path, and the Opam install step
#   runs those instructions.
#   Finally, there are base packages like `threads/META` that come from ocamlfind's
#   `make install-meta`. Use an Opam module like
#   https://github.com/ocaml/opam-repository/blob/master/packages/ocamlfind-secondary/ocamlfind-secondary.1.9.1/opam
#   to install those into <PREFIX_DIR>/<dkmlabi>-sysroot/lib.
# stdlib(<dkmlabi>) = "<MLCROSS_DIR>/<dkmlabi>/lib"
#   Built-in package libraries like `threads.cmxa` can be located
#   in `<MLCROSS_DIR>/<dkmlabi>/lib/``.
# destdir(<dkmlabi>) = "<MLCROSS_DIR>/<dkmlabi>/lib"
#   Newly cross-compiled packages will be added to this `destdir`
# ocamlc(<dkmlabi>) = "<MLCROSS_DIR>/<dkmlabi>/bin/ocamlc.opt"
#   The cross-compiler ocamlc. Other binaries (ex. ocamlopt) are added as well.
#   Some binaries may be bytecode executables while some may be native
#   executables.
set -euf

# ------------------
# BEGIN Command line processing

usage() {
  {
    printf "%s\n" "Usage:"
    printf "%s\n" "    r-c-ocaml-3-build_cross.sh"
    printf "%s\n" "        -h             Display this help message."
    printf "%s\n" "        -d DIR -t DIR  Compile OCaml."
    printf "\n"
    printf "%s\n" "See 'r-c-ocaml-1-setup.sh -h' for more comprehensive docs."
    printf "\n"
    printf "%s\n" "If not '-a TARGETABIS' is specified, this script does nothing"
    printf "\n"
    printf "%s\n" "Options"
    printf "%s\n" "   -s OCAMLVER: The OCaml version"
    printf "%s\n" "   -d DIR: DKML directory containing a .dkmlroot file"
    printf "%s\n" "   -t DIR: Target directory for the reproducible directory tree"
    printf "%s\n" "   -a TARGETABIS: Optional. See r-c-ocaml-1-setup.sh"
    printf "%s\n" "   -B Build bytecode compiler and libraries."
    printf "%s\n" "   -X Use bx32 ABI so OCaml (not C) is 32-bit. Effective only with -B, and works on 64-bit targets."
    printf "%s\n" "   -e DKMLHOSTABI: Uses the DkML compiler detector find a host ABI compiler"
    printf "%s\n" "   -f HOSTSRC_SUBDIR: Use HOSTSRC_SUBDIR subdirectory of -t DIR to place the source code of the host ABI"
    printf "%s\n" "   -g CROSS_SUBDIR: Use CROSS_SUBDIR subdirectory of -t DIR to place target ABIs"
    printf "%s\n" "   -l FLEXLINKFLAGS: Options added to flexlink while building ocaml, ocamlc, etc. native Windows executables"
    printf "%s\n" "   -n CONFIGUREARGS: Optional. Extra arguments passed to OCaml's ./configure. --with-flexdll"
    printf "%s\n" "      and --host will have already been set appropriately, but you can override the --host heuristic by adding it"
    printf "%s\n" "      to -n CONFIGUREARGS. Can be repeated."
    printf "%s\n" "   -w Disable non-essentials like the native toplevel and ocamldoc."
    printf "%s\n" "   -A Enable Address Sanitizer"
    printf "%s\n" "   -L Enable Leak Sanitizer"
  } >&2
}

_OCAMLVER=
DKMLDIR=
TARGETDIR=
TARGETABIS=
CONFIGUREARGS=
DKMLHOSTABI=
HOSTSRC_SUBDIR=
CROSS_SUBDIR=
FLEXLINKFLAGS=
DISABLE_EXTRAS=0
BYTECODEONLY=OFF
BX32=OFF
SANITIZE_ADDRESS=OFF
SANITIZE_LEAK=OFF
while getopts ":s:d:t:a:BXn:e:f:g:l:wALh" opt; do
  case ${opt} in
  h)
    usage
    exit 0
    ;;
  w) DISABLE_EXTRAS=1 ;;
  s)
    _OCAMLVER="$OPTARG"
    ;;
  d)
    DKMLDIR="$OPTARG"
    if [ ! -e "$DKMLDIR/.dkmlroot" ]; then
      printf "%s\n" "Expected a DKMLDIR at $DKMLDIR but no .dkmlroot found" >&2
      usage
      exit 1
    fi
    DKMLDIR=$(cd "$DKMLDIR" && pwd) # absolute path
    ;;
  t)
    TARGETDIR="$OPTARG"
    ;;
  a)
    TARGETABIS="$OPTARG"
    ;;
  B ) BYTECODEONLY=ON ;;
  X ) BX32=ON ;;
  n)
    CONFIGUREARGS="$CONFIGUREARGS $OPTARG"
    ;;
  e)
    DKMLHOSTABI="$OPTARG"
    ;;
  f ) HOSTSRC_SUBDIR=$OPTARG ;;
  g ) CROSS_SUBDIR=$OPTARG ;;
  l ) FLEXLINKFLAGS="$OPTARG" ;;
  A ) SANITIZE_ADDRESS=ON ;;
  L ) SANITIZE_LEAK=ON ;;
  \?)
    printf "%s\n" "This is not an option: -$OPTARG" >&2
    usage
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "$_OCAMLVER" ] || [ -z "$DKMLDIR" ] || [ -z "$TARGETDIR" ] || [ -z "$DKMLHOSTABI" ] || [ -z "$HOSTSRC_SUBDIR" ] || [ -z "$CROSS_SUBDIR" ]; then
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

# Quick exit
if [ -z "$TARGETABIS" ]; then
  exit 0
fi

# ------------------
# BEGIN Target ABI OCaml
#
# Most of this section was adapted from
# https://github.com/EduardoRFS/reason-mobile/blob/7ba258319b87943d2eb0d8fb84562d0afeb2d41f/patches/ocaml/files/make.cross.sh
# and https://github.com/anmonteiro/nix-overlays/blob/79d36ea351edbaf6ee146d9bf46b09ee24ed6ece/cross/ocaml.nix
# after discussion from authors at https://discuss.ocaml.org/t/cross-compiling-implementations-how-they-work/8686 .
# Portable shell linting (shellcheck) fixes applied.

# Prereqs for r-c-ocaml-functions.sh
autodetect_system_binaries
autodetect_system_path
autodetect_cpus
autodetect_posix_shell
export_safe_tmpdir

# shellcheck disable=SC1091
. "$DKMLDIR/vendor/dkml-compiler/src/r-c-ocaml-functions.sh"

compiler_clear_environment

## Parameters

if [ -x /usr/bin/cygpath ]; then
  # Makefiles have very poor support for Windows paths, so use mixed (ex. C:/Windows) paths
  OCAMLSRC_MIXED=$(/usr/bin/cygpath -am "$TARGETDIR_UNIX/$HOSTSRC_SUBDIR")
else
  OCAMLSRC_MIXED="$TARGETDIR_UNIX/$HOSTSRC_SUBDIR"
fi
export OCAMLSRC_MIXED

# Probe the artifacts from ./configure already done by the host ABI and host ABI's ./ocamlc
init_hostvars

# Probe host config variables that force target config variables.
# For example, if host has disabled function sections (done automatically by host ./configure
# usually based on detected platform), then target must also disable function sections or
# else get:
#  /xxx/build_android_arm64v8a/DkSDKFiles/o/s/o/src/ocaml/ocamlopt.opt: OCaml has been configured without support for -function-sections.
# when trying to compile the target cross-compiler with the host compiler.
HOST_FUNCTION_SECTIONS=$("$OCAMLSRC_MIXED/ocamlc$HOST_EXE_EXT" -config-var function_sections)
case $HOST_FUNCTION_SECTIONS in
    false) CONFIGUREARGS="--disable-function-sections${CONFIGUREARGS:+ $CONFIGUREARGS}" ;;
esac

if [ "$BYTECODEONLY" = ON ]; then
    CONFIGUREARGS="$CONFIGUREARGS --disable-native-compiler"
fi

# Get the variables for runtime/sak
#       shellcheck disable=SC1091
. "$OCAMLSRC_MIXED/runtime/sak.source.sh"

make_target() {
  make_target_ABI=$1
  shift
  make_target_BUILD_ROOT=$1
  shift

  # BUILD_ROOT is passed to `ocamlrun .../ocamlmklink -o unix -oc unix -ocamlc '$(CAMLC)'`
  # in Makefile, so needs to be mixed Unix/Win32 path. Also the just mentioned example is
  # run from the Command Prompt on Windows rather than MSYS2 on Windows, so use /usr/bin/env
  # to always switch into Unix context.
  CAMLC="$HOST_SPACELESS_ENV_MIXED_EXE $make_target_BUILD_ROOT/support/ocamlcTarget.wrapper" \
  CAMLOPT="$HOST_SPACELESS_ENV_MIXED_EXE $make_target_BUILD_ROOT/support/ocamloptTarget.wrapper" \
  make_caml "$make_target_ABI" BUILD_ROOT="$make_target_BUILD_ROOT" \
  SAK_CC="$SAK_CC" SAK_CFLAGS="$SAK_CFLAGS" SAK_LINK="$SAK_LINK" \
  "$@"
}

# Get a triplet that can be used by OCaml's ./configure.
# See https://github.com/ocaml/ocaml/blob/35af4cddfd31129391f904167236270a004037f8/configure#L14306-L14334
# for the Android triplet format.
ocaml_android_triplet() {
  ocaml_android_triplet_ABI=$1
  shift

  if [ "${DKML_COMPILE_TYPE:-}" = CM ] && [ -n "${DKML_COMPILE_CM_CMAKE_C_COMPILER_TARGET:-}" ]; then
    # CMAKE_C_COMPILER_TARGET=armv7-none-linux-androideabi16 (etc.)
    # However, the LLVM triple should not include the Android API level as a suffix.
    # Confer https://developer.android.com/ndk/guides/other_build_systems or
    # https://android.googlesource.com/platform/ndk/+/master/meta/abis.json.
    # So strip the Android API level from CMAKE_C_COMPILER_TARGET.
    case "$DKML_COMPILE_CM_CMAKE_C_COMPILER_TARGET" in
    arm*-none-linux-android* | aarch64*-none-linux-android* | i686*-none-linux-android* | x86_64*-none-linux-android*)
      # armv7-none-linux-androideabi16 -> armv7-none-linux-androideabi
      printf "%s" "$DKML_COMPILE_CM_CMAKE_C_COMPILER_TARGET" | $DKMLSYS_SED 's/[0-9]*$//'
      return
      ;;
    esac
  fi
  # Use given DKML ABI to find OCaml triplet
  case "$ocaml_android_triplet_ABI" in
    android_x86)      printf "i686-none-linux-android\n" ;;
    android_x86_64)   printf "x86_64-none-linux-android\n" ;;
    # v7a uses soft-float not hard-float (eabihf). https://developer.android.com/ndk/guides/abis#v7a
    android_arm32v7a) printf "armv7-none-linux-androideabi\n" ;;
    # v8a probably doesn't use hard-float since removed in https://android.googlesource.com/platform/ndk/+/master/docs/HardFloatAbi.md
    android_arm64v8a) printf "aarch64-none-linux-androideabi\n" ;;
    # fallback to v6 (Raspberry Pi 1, Raspberry Pi Zero). Raspberry Pi uses soft-float;
    # https://www.raspbian.org/RaspbianFAQ#What_is_Raspbian.3F . We do the same since it has most market
    # share
    *)                printf "armv5-none-linux-androideabi\n" ;;
  esac
}

build_world() {
  build_world_BUILD_ROOT=$1
  shift
  build_world_PREFIX=$1
  shift
  build_world_TARGET_ABI=$1
  shift
  build_world_POSTTRANSFORM=$1
  shift

  # PREFIX is captured in `ocamlc -config` so it needs to be a mixed Unix/Win32 path.
  # BUILD_ROOT is used in `ocamlopt.opt -I ...` so it needs to be a native path or mixed Unix/Win32 path.
  if [ -x /usr/bin/cygpath ]; then
    build_world_PREFIX=$(/usr/bin/cygpath -am "$build_world_PREFIX")
    build_world_BUILD_ROOT=$(/usr/bin/cygpath -am "$build_world_BUILD_ROOT")
  fi

  case "$build_world_TARGET_ABI" in
  windows_*)
    build_world_TARGET_EXE_EXT=.exe ;;
  *)
    build_world_TARGET_EXE_EXT= ;;
  esac

  # Are we consistently Win32 host->target or consistently Unix host->target? If not we will
  # have some C functions that are missing.
  case "$DKMLHOSTABI" in
  windows_*)
    case "$build_world_TARGET_ABI" in
    windows_*) build_world_WIN32UNIX_CONSISTENT=ON ;;
    *) build_world_WIN32UNIX_CONSISTENT=OFF ;;
    esac
    ;;
  *)
    case "$build_world_TARGET_ABI" in
    windows_*) build_world_WIN32UNIX_CONSISTENT=OFF ;;
    *) build_world_WIN32UNIX_CONSISTENT=ON ;;
    esac
    ;;
  esac
  if [ "$build_world_WIN32UNIX_CONSISTENT" = OFF ]; then
    printf "FATAL: You cannot cross-compile between Windows and Unix\n"
    exit 107
  fi

  # Make C compiler script for target ABI. Any compile spec (especially from CMake) will be
  # applied.
  install -d "$build_world_BUILD_ROOT"/support
  #   Exports OCAML_HOST_TRIPLET and DKML_TARGET_SYSROOT
  DKML_HOST_ABI="$DKMLHOSTABI" DKML_TARGET_ABI="$build_world_TARGET_ABI" \
    autodetect_compiler \
    --post-transform "$build_world_POSTTRANSFORM" \
    "$build_world_BUILD_ROOT"/support/with-target-c-compiler.sh
  #   To save a lot of troubleshooting time, we'll dump details
  $DKMLSYS_INSTALL -d "$build_world_PREFIX/share/dkml/detect"
  $DKMLSYS_INSTALL "$build_world_POSTTRANSFORM" "$build_world_PREFIX/share/dkml/detect/post-transform.sh"

  # Target wrappers
  if [ "$BYTECODEONLY" = OFF ]; then
    #   shellcheck disable=SC2086
    log_trace genWrapper "$build_world_BUILD_ROOT/support/ocamlcTarget.wrapper" "$build_world_BUILD_ROOT"/support/with-target-c-compiler.sh "$OCAMLSRC_MIXED"/support/with-linking-on-host.sh "$build_world_BUILD_ROOT/ocamlc.opt$build_world_TARGET_EXE_EXT" -I "$build_world_BUILD_ROOT/stdlib" -I "$build_world_BUILD_ROOT/otherlibs/unix" -nostdlib
    #   shellcheck disable=SC2086
    log_trace genWrapper "$build_world_BUILD_ROOT/support/ocamloptTarget.wrapper" "$build_world_BUILD_ROOT"/support/with-target-c-compiler.sh "$OCAMLSRC_MIXED"/support/with-linking-on-host.sh "$build_world_BUILD_ROOT/ocamlopt.opt$build_world_TARGET_EXE_EXT" -I "$build_world_BUILD_ROOT/stdlib" -I "$build_world_BUILD_ROOT/otherlibs/unix" -nostdlib
  else
    # bytecode-only, so use ocamlrun ocamlc not ocamlc.opt. we need ocamlrun from the host ABI so it can run
    #   shellcheck disable=SC2086
    log_trace genWrapper "$build_world_BUILD_ROOT/support/ocamlcTarget.wrapper" \
      "$build_world_BUILD_ROOT"/support/with-target-c-compiler.sh \
      "$OCAMLSRC_MIXED"/support/with-linking-on-host.sh \
      "$OCAMLSRC_MIXED/runtime/ocamlrun$build_world_TARGET_EXE_EXT" \
      "$build_world_BUILD_ROOT/ocamlc$build_world_TARGET_EXE_EXT" \
      -I "$build_world_BUILD_ROOT/stdlib" -I "$build_world_BUILD_ROOT/otherlibs/unix" \
      -nostdlib
  fi

  # clean (otherwise you will 'make inconsistent assumptions' errors with a mix of host + target binaries)
  #   note: If re-running after -R 500, we need access to delete files during clean. So chmod.
  log_trace "$DKMLSYS_CHMOD" -R ug+w    stdlib/
  make clean

  # provide --host for use in `checking whether we are cross compiling` ./configure step
  case "$build_world_TARGET_ABI" in
  android_*)
    build_world_HOST_TRIPLET=$(ocaml_android_triplet "$build_world_TARGET_ABI")
    ;;
  *)
    # This is a fallback, just not a perfect one
    build_world_HOST_TRIPLET=$("$build_world_BUILD_ROOT"/build-aux/config.guess)
    ;;
  esac

  # check if we'll build native toplevel
  case "$BYTECODEONLY,$DISABLE_EXTRAS,$_OCAMLVER" in
    OFF,0,4.14.*|OFF,0,5.*)
        # Install native toplevel
        native_toplevel=full
        CONFIGUREARGS="--enable-native-toplevel${CONFIGUREARGS:+ $CONFIGUREARGS}"
        ;;
    *)
        native_toplevel=off ;;
  esac


  # ./configure
  log_trace ocaml_configure "$build_world_PREFIX" "$build_world_TARGET_ABI" \
    "$build_world_BUILD_ROOT"/support/with-target-c-compiler.sh "$OCAML_HOST_TRIPLET" "$DKML_TARGET_SYSROOT" \
    "--host=$build_world_HOST_TRIPLET $CONFIGUREARGS --disable-ocamldoc"

  # Extend m.h
  if [ "$BYTECODEONLY" = ON ] && [ "$BX32" = ON ]; then
    print_m_h_extensions "$build_world_TARGET_ABI" __bx32 >> runtime/caml/m.h
  else
    print_m_h_extensions "$build_world_TARGET_ABI" "" >> runtime/caml/m.h
  fi

  # Extend Makefile.config
  print_makefile_config_extensions "$SANITIZE_ADDRESS" "$SANITIZE_LEAK" >> Makefile.config

  # Build
  # -----

  # Make a host ABI form of 'sak' (Runtime Builder's Swiss Army Knife)
  case "$_OCAMLVER" in
    4.14.*|5.*)
      log_trace make_host -final -C runtime "sak$build_world_TARGET_EXE_EXT" \
        SAK_CC="$SAK_CC" SAK_CFLAGS="$SAK_CFLAGS" SAK_LINK="$SAK_LINK"
      ;;
  esac

  # Make non-boot ./ocamlc and ./ocamlopt compiler
  if [ "$OCAML_CONFIGURE_NEEDS_MAKE_FLEXDLL" = ON ]; then
    log_trace make_host -final flexdll
  fi
  log_trace make_host -final runtime coreall
  if [ "$BYTECODEONLY" = OFF ]; then
    #   Build ocamlc.opt which needs opt-core
    log_trace make_host -final opt-core
    log_trace make_host -final ocamlc.opt NATIVECCLIBS= BYTECCLIBS= # host and target C libraries don't mix
    #   Troubleshooting
    {
      printf "+ '%s/ocamlc.opt' -config\n" "$build_world_BUILD_ROOT" >&2
      "$build_world_BUILD_ROOT"/ocamlc.opt -config >&2
    }
    log_trace make_host -final ocamlopt.opt
  else
    log_trace make_host -final ocamlc
  fi

  # Tools we want that we can compile using the OCaml compiler to run on the host.
  # Separate ocaml from the others to avoid race condition `Could not finding .cmi file
  # for interface .../genprintval.mli` (Apple M1 -> android_arm64v8a; 4.14.0)
  log_trace make_host -final ocaml
  if [ "$BYTECODEONLY" = OFF ]; then
    log_trace make_host -final ocamldebugger ocamllex.opt ocamltoolsopt
  else
    log_trace make_host -final ocamldebugger ocamllex ocamltools
  fi

  # Tools we don't need but are needed by `install` target
  log_trace make_host -final expunge

  # Remove all OCaml compiled modules since they were compiled with boot/ocamlc
  remove_compiled_objects_from_curdir

  # Recompile stdlib (and flexdll if enabled)
  #   See notes in 2-build_host.sh for why we compile twice.
  #   (We have to serialize the make_ commands because OCaml Makefile do not usually build multiple targets in parallel)
  if [ "$BYTECODEONLY" = OFF ] && [ "$OCAML_CONFIGURE_NEEDS_MAKE_FLEXDLL" = ON ]; then
    printf "+ INFO: Compiling host flexdll in pass 1\n" >&2
    log_trace make_host -compile-stdlib flexdll
  fi
  printf "+ INFO: Compiling host stdlib in pass 1\n" >&2
  log_trace make_host -final  -C stdlib all
  if [ "$BYTECODEONLY" = OFF ]; then
    printf "+ INFO: Compiling host optimized stdlib in pass 1\n" >&2
    log_trace make_host -final  -C stdlib allopt
  fi
  printf "+ INFO: Recompiling host ocamlc in pass 1\n" >&2
  log_trace make_host -final  ocamlc
  if [ "$BYTECODEONLY" = OFF ]; then
    #   ocamlopt needed to build ocamlc.opt
    printf "+ INFO: Recompiling host ocamlopt in pass 1\n" >&2
    log_trace make_host -final  ocamlopt
    printf "+ INFO: Recompiling host ocamlc.opt in pass 1\n" >&2
    log_trace make_host -final  ocamlc.opt
    printf "+ INFO: Recompiling host ocamlopt.opt in pass 1\n" >&2
    log_trace make_host -final  ocamlopt.opt
  fi
  printf "+ INFO: Recompiling host stdlib in pass 2\n" >&2
  log_trace make_host -final  -C stdlib all
  if [ "$BYTECODEONLY" = OFF ]; then
    printf "+ INFO: Recompiling host optimized stdlib in pass 2\n" >&2
    log_trace make_host -final  -C stdlib allopt
  fi

  # Remove all OCaml compiled modules since they were compiled for the host ABI
  remove_compiled_objects_from_curdir

  # ------------------------------------------------------------------------------------
  # From this point on we do _not_ build {ocamlc,ocamlopt,*}.opt native code executables
  # because they have to run on the host. We already built those! They have all the
  # settings from ./configure which is tuned for the target ABI.
  # vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  # Recompile stdlib (and flexdll if enabled)
  #   See notes in 2-build_host.sh for why we compile twice
  #   (We have to serialize the make_ commands because OCaml Makefile do not usually build multiple targets in parallel)
  if [ "$BYTECODEONLY" = OFF ] && [ "$OCAML_CONFIGURE_NEEDS_MAKE_FLEXDLL" = ON ]; then
    log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" flexdll
  fi
  printf "+ INFO: Compiling target stdlib in pass 1\n" >&2
  log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" -C stdlib all
  if [ "$BYTECODEONLY" = OFF ]; then
    printf "+ INFO: Compiling target optimized stdlib in pass 1\n" >&2
    log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" -C stdlib allopt
  fi
  printf "+ INFO: Recompiling target ocaml in pass 1\n" >&2
  log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" ocaml
  printf "+ INFO: Recompiling target ocamlc in pass 1\n" >&2
  log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" ocamlc
  if [ "$BYTECODEONLY" = OFF ]; then
    #   ocamlopt needed to build ocamlc.opt
    printf "+ INFO: Recompiling target ocamlopt in pass 1\n" >&2
    log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" ocamlopt
    printf "+ INFO: Recompiling target optimized stdlib in pass 2\n" >&2
    log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" -C stdlib all allopt
  else
    printf "+ INFO: Recompiling target stdlib in pass 2\n" >&2
    log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" -C stdlib all
  fi
  log_trace "$DKMLSYS_CHMOD" -R 500 stdlib/

  printf "+ INFO: Compiling target libraries in pass 2\n" >&2
  log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" otherlibraries
  if [ "$BYTECODEONLY" = OFF ]; then
    printf "+ INFO: Compiling target optimized libraries and tools in pass 2\n" >&2
    log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" otherlibrariesopt
    log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" ocamltoolsopt
  fi
  case "$native_toplevel" in
    compile)
        # Install compiled objects needed for [installoptopt] target
        log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" \
          toplevel/toploop.cmx toplevel/native/tophooks.cmi toplevel/native/topmain.cmx \
          toplevel/topstart.cmx
        ;;
    full)
        # Install native toplevel
        log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" \
          "ocamlnat$build_world_TARGET_EXE_EXT" \
          toplevel/toploop.cmx
        ;;
    off) ;; # to document that 'off' is a valid enumeration value
  esac
  if [ "$BYTECODEONLY" = OFF ]; then
    #   stop warning about native binary older than bytecode binary
    log_trace touch "lex/ocamllex.opt${build_world_TARGET_EXE_EXT}"
    log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" driver/main.cmx driver/optmain.cmx \
      compilerlibs/ocamlcommon.cmxa \
      compilerlibs/ocamlbytecomp.cmxa \
      compilerlibs/ocamloptcomp.cmxa
  else
    #   stop warning about native binary older than bytecode binary
    log_trace touch "lex/ocamllex${build_world_TARGET_EXE_EXT}"
    log_trace make_target "$build_world_TARGET_ABI" "$build_world_BUILD_ROOT" driver/main.cmo \
      compilerlibs/ocamlcommon.cma \
      compilerlibs/ocamlbytecomp.cma
  fi

  ## Install
  log_trace "$DKMLSYS_CHMOD" -R ug+w    stdlib/ # Restore file permissions
  "$DKMLSYS_INSTALL" -v -d "$build_world_PREFIX/bin" "$build_world_PREFIX/lib/ocaml"
  "$DKMLSYS_INSTALL" -v "runtime/ocamlrun$build_world_TARGET_EXE_EXT" "$build_world_PREFIX/bin/"
  log_trace make_host -final            install
  log_trace make_host -final            -C debugger install

  # Some binaries may not be compiled (depends on the version), and should just be
  # the host standard binaries.
  if [ -x "$OCAMLSRC_MIXED/runtime/ocamlrund$build_world_TARGET_EXE_EXT" ]; then
    "$DKMLSYS_INSTALL" -v "$OCAMLSRC_MIXED/runtime/ocamlrund$build_world_TARGET_EXE_EXT" "$build_world_PREFIX/bin/"
  fi
  if [ -x "$OCAMLSRC_MIXED/runtime/ocamlruni$build_world_TARGET_EXE_EXT" ]; then
    "$DKMLSYS_INSTALL" -v "$OCAMLSRC_MIXED/runtime/ocamlruni$build_world_TARGET_EXE_EXT" "$build_world_PREFIX/bin/"
  fi
  "$DKMLSYS_INSTALL" -v "$OCAMLSRC_MIXED/yacc/ocamlyacc$build_world_TARGET_EXE_EXT" "$build_world_PREFIX/bin/"

  # Cross-compilation of [dkml-component-staging-opam64] broke when opam upgraded to [dose3.7.0.0]:
  #   File "src_ext/dose3/src/common/dune", line 16, characters 0-255:
  #   16 | (rule
  #   17 |  (targets gitVersionInfo.ml)
  #   18 |  ; Ensures the hash update whenever a source file is modified ;
  #   19 |  (deps
  #   20 |   (source_tree %{workspace_root}/.git)
  #   21 |   (:script get-git-info.mlt))
  #   22 |  (action
  #   23 |   (with-stdout-to
  #   24 |    %{targets}
  #   25 |    (run %{ocaml} unix.cma %{script}))))
  #   (cd _build/default.darwin_arm64/src_ext/dose3/src/common && /Users/runner/.opam/dkml/share/dkml-base-compiler/mlcross/darwin_arm64/bin/ocaml unix.cma get-git-info.mlt) > _build/default.darwin_arm64/src_ext/dose3/src/common/gitVersionInfo.ml
  #   Cannot load required shared library dllunix.
  #   Reason: /Users/runner/.opam/dkml/share/dkml-base-compiler/mlcross/darwin_arm64/lib/ocaml/stublibs/dllunix.so: dlopen(/Users/runner/.opam/dkml/share/dkml-base-compiler/mlcross/darwin_arm64/lib/ocaml/stublibs/dllunix.so, 0x000A): tried: '/Users/runner/.opam/dkml/share/dkml-base-compiler/mlcross/darwin_arm64/lib/ocaml/stublibs/dllunix.so' (mach-o file, but is an incompatible architecture (have (arm64), need (x86_64))).
  # That is because `mlcross/darwin_arm64/bin/ocaml` must be compiled with the standard library
  # location of the host compiler. Compiling it with the host compiler is not enough ...
  # the ocaml executable will still be hardcoded to use the stdlib of `mlcross/darwin_arm64`.
  # Just re-use the host standard ocaml.
  "$DKMLSYS_INSTALL" -v "$OCAMLSRC_MIXED/ocaml$build_world_TARGET_EXE_EXT" "$build_world_PREFIX/bin/"
}

add_text() {
  add_text_FILE=$1
  shift
  #   shellcheck disable=SC2034
  add_text_SEARCH=$1 # ignored this version
  shift
  add_text_TEXT_IF_MISSING=$1
  shift
  # if grep -q "$add_text_SEARCH" "$add_text_FILE"; then
  #   return 0
  # fi
  printf "%s\n" "$add_text_TEXT_IF_MISSING" >> "$add_text_FILE"
}

add_findlib_conf() {
    # ex. android_arm32v7a
    add_findlib_conf_ABI=$1; shift
    # ex. <switch>/share/dkml-base-compiler/mlcross/android_arm64v8a
    add_findlib_conf_CROSSTARGET=$1; shift

    install -d "$TARGETDIR_UNIX/lib/findlib.conf.d"
    add_findlib_conf_CONF="$TARGETDIR_UNIX/lib/findlib.conf.d/$add_findlib_conf_ABI.conf"

    # Ex. path(android_arm32v7a)="C:\\source\\windows_x86_64\\lib"
    # Any backslashes need to be escaped since it is an OCaml string
    bin_buildhost="$add_findlib_conf_CROSSTARGET/bin"
    lib_buildhost="$add_findlib_conf_CROSSTARGET/lib"
    sysroot_lib_buildhost="$TARGETDIR_UNIX/$add_findlib_conf_ABI-sysroot/lib"
    install -d "$sysroot_lib_buildhost" # needed for realpath to work, even if won't be populated until conf-dkml-cross-toolchain
    _dirsep="/"
    _findsep=":"
    _exe=""
    if [ -x /usr/bin/cygpath ]; then
        bin_buildhost=$(/usr/bin/cygpath -aw "$bin_buildhost")
        lib_buildhost=$(/usr/bin/cygpath -aw "$lib_buildhost")
        sysroot_lib_buildhost=$(/usr/bin/cygpath -aw "$sysroot_lib_buildhost")
        _dirsep="\\\\"
        _exe=".exe"
        _findsep=";"
    elif [ -x /usr/bin/realpath ]; then
        bin_buildhost=$(/usr/bin/realpath "$bin_buildhost")
        lib_buildhost=$(/usr/bin/realpath "$lib_buildhost")
        sysroot_lib_buildhost=$(/usr/bin/realpath "$sysroot_lib_buildhost")
    fi
    bin_buildhost=$(escape_arg_as_ocaml_string "$bin_buildhost")
    lib_buildhost=$(escape_arg_as_ocaml_string "$lib_buildhost")

    {
      printf "%s\n"     "path($add_findlib_conf_ABI) = \"$lib_buildhost${_findsep}$sysroot_lib_buildhost\""
      printf "%s\n"     "destdir($add_findlib_conf_ABI) = \"$sysroot_lib_buildhost\""
      printf "%s\n"     "stdlib($add_findlib_conf_ABI) = \"$lib_buildhost${_dirsep}ocaml\""
      if [ "$BYTECODEONLY" = OFF ] && [ -e "$add_findlib_conf_CROSSTARGET/bin/flexlink.exe" ]; then
          printf "%s\n" "flexlink($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}flexlink.exe\""
      fi
      printf "%s\n"     "ocaml($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocaml${_exe}\""
      printf "%s\n"     "ocamlc($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamlc.opt${_exe}\""
      printf "%s\n"     "ocamlcmt($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamlcmt${_exe}\""
      printf "%s\n"     "ocamlcp($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamlcp.byte${_exe}\""
      printf "%s\n"     "ocamldebug($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamldebug${_exe}\""
      printf "%s\n"     "ocamldep($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamldep.byte${_exe}\""
      printf "%s\n"     "ocamllex($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamllex.opt${_exe}\""
      printf "%s\n"     "ocamlmklib($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamlmklib.byte${_exe}\""
      printf "%s\n"     "ocamlmktop($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamlmktop.byte${_exe}\""
      printf "%s\n"     "ocamlobjinfo($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamlobjinfo.byte${_exe}\""
      if [ "$BYTECODEONLY" = OFF ]; then
        printf "%s\n"     "ocamlopt($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamlopt.opt${_exe}\""
        printf "%s\n"     "ocamloptp($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamloptp.byte${_exe}\""
      fi
      printf "%s\n"     "ocamlprof($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamlprof.byte${_exe}\""
      printf "%s\n"     "ocamlrun($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamlrun${_exe}\""
      printf "%s\n"     "ocamlrund($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamlrund${_exe}\""
      printf "%s\n"     "ocamlruni($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamlruni${_exe}\""
      printf "%s\n"     "ocamlyacc($add_findlib_conf_ABI) = \"$bin_buildhost${_dirsep}ocamlyacc${_exe}\""
    } > "$add_findlib_conf_CONF"
}

# Loop over each target abi script file; each file separated by semicolons, and each term with an equals
printf "%s\n" "$TARGETABIS" | sed 's/;/\n/g' | sed 's/^\s*//; s/\s*$//' > "$WORK"/target-abis
log_script "$WORK"/target-abis
while IFS= read -r _abientry; do
  _targetabi=$(printf "%s" "$_abientry" | sed 's/=.*//')
  _abiscript=$(printf "%s" "$_abientry" | sed 's/^[^=]*=//')

  case "$_abiscript" in
  /* | ?:*) # /a/b/c or C:\Windows
    ;;
  *) # relative path; need absolute path since we will soon change dir to $_CROSS_SRCDIR
    _abiscript="$DKMLDIR/$_abiscript"
    ;;
  esac

  # Compile the cross-compiler
  _CROSS_TARGETDIR=$TARGETDIR_UNIX/$CROSS_SUBDIR/$_targetabi
  _CROSS_SRCDIR=$_CROSS_TARGETDIR/$HOSTSRC_SUBDIR
  cd "$_CROSS_SRCDIR"
  build_world "$_CROSS_SRCDIR" "$_CROSS_TARGETDIR" "$_targetabi" "$_abiscript"

  # Create lib/findlib.conf.d/android_arm64.conf (etc.)
  cd "$TARGETDIR_UNIX"
  add_findlib_conf "$_targetabi" "$_CROSS_TARGETDIR"

done <"$WORK"/target-abis

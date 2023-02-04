#!/bin/sh
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
# Used by DKML's autodetect_compiler() function to customize compiler
# variables before the variables are written to a launcher script.
#
# On entry autodetect_compiler() will have populated some or all of the
# following non-export variables:
#
# * DKML_TARGET_ABI. Always available
# * autodetect_compiler_CFLAGS
# * autodetect_compiler_CC
# * autodetect_compiler_CXX
# * autodetect_compiler_CFLAGS
# * autodetect_compiler_CXXFLAGS
# * autodetect_compiler_AS
# * autodetect_compiler_ASFLAGS
# * autodetect_compiler_LDFLAGS
# * autodetect_compiler_LDLIBS
# * autodetect_compiler_MSVS_NAME
# * autodetect_compiler_MSVS_INC. Separated by semicolons. No trailing semicolon.
# * autodetect_compiler_MSVS_LIB. Separated by semicolons. No trailing semicolon.
# * autodetect_compiler_MSVS_PATH. Unix PATH format with no trailing colon.
#
# Generally the variables conform to the description in
# https://www.gnu.org/software/make/manual/html_node/Implicit-Variables.html.
# The compiler will have been chosen from:
# a) find the compiler selected/validated in the Diskuv OCaml installation
#    (Windows) or on first-use (Unix)
# b) the specific architecture that has been given in DKML_TARGET_ABI
#
# Also the function `export_binding NAME VALUE` will be available for you to
# add custom variables (like AR, NM, OBJDUMP, etc.) to the launcher script.
#
# On exit the `autodetect_compiler_VARNAME` variables may be changed by this
# script. They will then be used for github.com/ocaml/ocaml/configure.
#
# That is, you influence variables written to the launcher script by either:
# a) Changing autodetect_compiler_CFLAGS (etc.). Those values will be named as
#    CFLAGS (etc.) in the launcher script
# b) Explicitly adding names and values with `export_binding`

set -euf

# Microsoft cl.exe and link.exe use forward slash (/) options; do not ever let MSYS2 interpret
# the forward slash and try to convert it to a Windows path.
disambiguate_filesystem_paths

# ---------------------------------------
# github.com/ocaml/ocaml/configure output
# ---------------------------------------

# Pre-adjustments

#   This section can be replaced by outside actors like dkml-base-compiler.opam to inject
#   custom options. Just replace any or all of the following:
#     <start of line>INJECT_CFLAGS=<end of line>
#     <start of line>DEFAULT_AS=<end of line>
#     <start of line>INJECT_ASFLAGS=<end of line>
INJECT_CFLAGS=
if [ -n "${autodetect_compiler_CFLAGS:-}" ]; then
  autodetect_compiler_CFLAGS="$INJECT_CFLAGS $autodetect_compiler_CFLAGS"
else
  autodetect_compiler_CFLAGS="$INJECT_CFLAGS"
fi
DEFAULT_AS=
if [ -z "${autodetect_compiler_AS:-}" ]; then
  autodetect_compiler_AS="$DEFAULT_AS"
fi
INJECT_ASFLAGS=
if [ -n "${autodetect_compiler_ASFLAGS:-}" ]; then
  autodetect_compiler_ASFLAGS="$INJECT_ASFLAGS $autodetect_compiler_ASFLAGS"
else
  autodetect_compiler_ASFLAGS="$INJECT_ASFLAGS"
fi

#   CMake with Xcode will use a low-level compiler like
#   /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc
#   rather than the high-level compiler driver /usr/bin/clang; with the low-level compiler you
#   need to use `xcrun` to set required environment variables (SDKROOT, CPATH, LIBPATH; similar
#   to MSVC cl.exe needing vcvarsall.bat). Mitigate by just overwriting the compiler executables
#   if a) not already within `xcrun` and b) using AppleClang.
if [ -z "${SDKROOT:-}" ] && [ -z "${CPATH:-}" ] && [ -z "${LIBPATH:-}" ] && [ "${DKML_COMPILE_CM_CMAKE_C_COMPILER_ID:-}" = AppleClang ]; then
  autodetect_compiler_AS="clang"
  autodetect_compiler_CC="clang"
  autodetect_compiler_LD="ld"
  STRIP="strip"
  RANLIB="ranlib"
  NM="nm"
  OBJDUMP="objdump"
fi

# CC
# The value of this appears in `ocamlc -config`; will be viral to most Opam packages with embedded C code.
# clang and perhaps other compilers need --target=armv7-none-linux-androideabi21 for example
if [ -n "${autodetect_compiler_CC:-}" ]; then
  ORIG_CC=$autodetect_compiler_CC

  # OCaml's 4.14+ ./configure has func_cc_basename () which returns "gcc" if a GCC compiler, etc.
  # However it uses the basename ... so a symlink from /usr/bin/cc to to /etc/alternatives/cc to /usr/bin/gcc
  # to /usr/bin/x86_64-linux-gnu-gcc-9 for example (Ubuntu 20) would return "cc" and then code like
  # `./configure --enable-frame-pointers` would fail because it was looking for "gcc".
  #
  # Even worse, earlier versions of OCaml just used the variable "$CC" and checked if it was "gcc*".
  _GCCEXE=$(command -v gcc || true)
  if [ -n "$_GCCEXE" ] && [ -x /usr/bin/realpath ]; then
    # Mitigation GCC_EXE: See if $CC resolves to the same realpath as gcc. Use it if it does. But prefer
    # "gcc" if it is /usr/bin/gcc.
    _CC_1=$(/usr/bin/realpath "$autodetect_compiler_CC")
    _CC_2=$(/usr/bin/realpath "$_GCCEXE")
    _CC_RESOLVE=$_GCCEXE
    if [ "$_GCCEXE" = /usr/bin/gcc ]; then
      _CC_RESOLVE=gcc
    fi
    if [ "$_CC_1" = "$_CC_2" ]; then
      autodetect_compiler_CC=$_CC_RESOLVE
    fi
  fi

  # Add --target if necessary
  if [ -n "${DKML_COMPILE_CM_CMAKE_C_COMPILER_TARGET:-}" ]; then
    autodetect_compiler_CC="$autodetect_compiler_CC ${DKML_COMPILE_CM_CMAKE_C_COMPILE_OPTIONS_TARGET:-}${DKML_COMPILE_CM_CMAKE_C_COMPILER_TARGET:-}"
  fi
  # clang and perhaps other compilers need --sysroot=C:/Users/beckf/AppData/Local/Android/Sdk/ndk/21.4.7075529/toolchains/llvm/prebuilt/windows-x86_64/sysroot for example
  if [ -n "${DKML_COMPILE_CM_CMAKE_SYSROOT:-}" ]; then
    autodetect_compiler_CC="$autodetect_compiler_CC ${DKML_COMPILE_CM_CMAKE_C_COMPILE_OPTIONS_SYSROOT:-}${DKML_COMPILE_CM_CMAKE_SYSROOT:-}"
  fi

  # Clang compilers from Xcode should use clang -arch XXXX; the -arch won't be exported in CMake variables
  # And autodetect_darwin() correctly separates CC from CFLAGS ... but the internal `mksharedlib` ./configure
  # variable uses $CC to make shared libraries (ignoring $CFLAGS). So we have to add it in even if we don't
  # use CMake.
  # It is fine if there is duplication.
  if [ "${DKML_COMPILE_TYPE:-}" = CM ]; then
    case "$DKML_TARGET_ABI,${DKML_COMPILE_CM_CMAKE_C_COMPILER_ID:-}" in
      darwin_arm64,AppleClang|darwin_arm64,Clang)   autodetect_compiler_CC="$autodetect_compiler_CC -arch arm64" ;;
      darwin_x86_64,AppleClang|darwin_x86_64,Clang) autodetect_compiler_CC="$autodetect_compiler_CC -arch x86_64" ;;
    esac
  else
    case "$DKML_TARGET_ABI" in # Assume Clang compiler
      darwin_arm64)  autodetect_compiler_CC="$autodetect_compiler_CC -arch arm64" ;;
      darwin_x86_64) autodetect_compiler_CC="$autodetect_compiler_CC -arch x86_64" ;;
    esac
  fi
else
  ORIG_CC=
fi

# CFLAGS
# The value of this *does* appear in `ocamlc -config` so it is
# similar to CC. However CFLAGS is not used when building a shared
# library for github.com/ocaml/ocaml. So options that are agnostic
# to shared vs static libraries should be in CC.
if [ -n "${autodetect_compiler_CC:-}" ]; then
  # -m32 and -m64 are options that need to be in CC for OCaml
  if printf "%s" " ${autodetect_compiler_CFLAGS:-} " | PATH=/usr/bin:/bin grep -q ' -m32 '; then
      autodetect_compiler_CC="$autodetect_compiler_CC -m32"
      autodetect_compiler_CFLAGS=$(printf "%s" " $autodetect_compiler_CFLAGS " | PATH=/usr/bin:/bin sed 's/ -m32 / /g')
  fi
  if printf "%s" " ${autodetect_compiler_CFLAGS:-} " | PATH=/usr/bin:/bin grep -q ' -m64 '; then
      autodetect_compiler_CC="$autodetect_compiler_CC -m64"
      autodetect_compiler_CFLAGS=$(printf "%s" " $autodetect_compiler_CFLAGS " | PATH=/usr/bin:/bin sed 's/ -m64 / /g')
  fi

  # -Os is an option that should be in CC for OCaml
  # Confer: https://wiki.gentoo.org/wiki/GCC_optimization
  if printf "%s" " ${autodetect_compiler_CFLAGS:-} " | PATH=/usr/bin:/bin grep -q ' -Os '; then
      autodetect_compiler_CC="$autodetect_compiler_CC -Os"
      autodetect_compiler_CFLAGS=$(printf "%s" " $autodetect_compiler_CFLAGS " | PATH=/usr/bin:/bin sed 's/ -Os / /g')
  fi

  # -Z7 is an option that should be in CC for OCaml
  # Confer: https://learn.microsoft.com/en-us/cpp/build/reference/z7-zi-zi-debug-information-format?view=msvc-170
  if printf "%s" " ${autodetect_compiler_CFLAGS:-} " | PATH=/usr/bin:/bin grep -q ' -Z7 '; then
      autodetect_compiler_CC="$autodetect_compiler_CC -Z7"
      autodetect_compiler_CFLAGS=$(printf "%s" " $autodetect_compiler_CFLAGS " | PATH=/usr/bin:/bin sed 's/ -Z7 / /g')
  fi

  # -mmacosx-version-min=MM.NN needs to be in CC for OCaml
  if printf "%s" " ${autodetect_compiler_CFLAGS:-} " | PATH=/usr/bin:/bin grep -q ' -mmacosx-version-min=[0-9.]* '; then
    # sigh. vanilla sed does not have non-greedy regex so removing the -mmacosx-version-min=MM.NN is complex.
    _OSX_VMIN=$(printf "%s" " $autodetect_compiler_CFLAGS " | PATH=/usr/bin:/bin sed 's/.* -mmacosx-version-min=//; s/\([0-9.]*\) .*/\1/ ')
    autodetect_compiler_CC="$autodetect_compiler_CC -mmacosx-version-min=$_OSX_VMIN"
    autodetect_compiler_CFLAGS=$(printf "%s" " $autodetect_compiler_CFLAGS " | PATH=/usr/bin:/bin sed 's/ -mmacosx-version-min=[0-9.]* / /g')
  fi

  # For OCaml 5.00 there is an error with GCC:
  #   gc_ctrl.c:201:28: error: format ‘%zu’ expects argument of type ‘size_t’, but argument 3 has type ‘long unsigned int’ [-Werror=format=]
  case "${autodetect_compiler_CC:-}" in
    */gcc*|gcc*) autodetect_compiler_CFLAGS="${autodetect_compiler_CFLAGS:-} -Wno-format" ;;
  esac
fi

# https://github.com/ocaml/ocaml/blob/01c6f16cc69ce1d8cf157e66d5702fadaa18d247/configure.ac#L1213-L1240
if cmake_flag_on "${DKML_COMPILE_CM_MSVC:-}"; then
    # Use the MASM compiler (ml/ml64) which is required for OCaml with MSVC.
    # See https://github.com/ocaml/ocaml/blob/4c52549642873f9f738dd89ab39cec614fb130b8/configure#L14585-L14588 for options
    if [ "${DKML_COMPILE_CM_CONFIG:-}" = "Debug" ]; then
      _MLARG_EXTRA=" -Zi -Zd"
    else
      _MLARG_EXTRA=
    fi
    if [ "$DKML_COMPILE_CM_CMAKE_SIZEOF_VOID_P" -eq 4 ]; then
      autodetect_compiler_AS="${DKML_COMPILE_CM_CMAKE_ASM_MASM_COMPILER}${_MLARG_EXTRA} -nologo -coff -Cp -c -Fo"
    else
      autodetect_compiler_AS="${DKML_COMPILE_CM_CMAKE_ASM_MASM_COMPILER}${_MLARG_EXTRA} -nologo -Cp -c -Fo"
    fi
    ASPP="$autodetect_compiler_AS"
elif [ -n "${autodetect_compiler_AS:-}" ]; then
  autodetect_compiler_AS="${autodetect_compiler_AS:-}"
  if [ -n "${autodetect_compiler_AS:-}" ] && [ -n "${autodetect_compiler_ASFLAGS:-}" ]; then
    autodetect_compiler_AS="$autodetect_compiler_AS $autodetect_compiler_ASFLAGS"
  fi
  if [ -n "${DKML_COMPILE_CM_CMAKE_ASM_COMPILER_TARGET:-}" ]; then
    autodetect_compiler_AS="$autodetect_compiler_AS ${DKML_COMPILE_CM_CMAKE_ASM_COMPILE_OPTIONS_TARGET:-}${DKML_COMPILE_CM_CMAKE_ASM_COMPILER_TARGET:-}"
  fi

  # Some architectures need flags when compiling OCaml
  case "$DKML_TARGET_ABI" in
    darwin_*) autodetect_compiler_AS="$autodetect_compiler_AS -Wno-trigraphs" ;;
  esac
  # Clang compilers from Xcode should use clang ... -arch XXXX; the -arch won't be exported in CMAKE variables
  if [ "${DKML_COMPILE_TYPE:-}" = CM ]; then
    case "$DKML_TARGET_ABI,${DKML_COMPILE_CM_CMAKE_ASM_COMPILER_ID:-}" in
      darwin_arm64,AppleClang|darwin_arm64,Clang)   autodetect_compiler_AS="$autodetect_compiler_AS -arch arm64" ;;
      darwin_x86_64,AppleClang|darwin_x86_64,Clang) autodetect_compiler_AS="$autodetect_compiler_AS -arch x86_64" ;;
    esac
  fi

  # A CMake-configured `AS` will be missing the `-c` option needed by OCaml; fix that
  if printf "%s" " ${DKML_COMPILE_CM_CMAKE_ASM_COMPILE_OBJECT:-} " | PATH=/usr/bin:/bin grep -q -E -- ' -c '; then
    # CMAKE_ASM_COMPILE_OBJECT contains '-c' as a single word. Ex: <CMAKE_ASM_COMPILER> <DEFINES> <INCLUDES> <FLAGS> -o <OBJECT> -c <SOURCE>
    autodetect_compiler_AS="$autodetect_compiler_AS -c"
  fi

  # By default ASPP is the same as AS. But since ASPP involves preprocessing and many assemblers do not include
  # preprocessing, we may need to look at the C compiler (ex. clang) and see if we should override ASPP.
  ASPP="$autodetect_compiler_AS"
  case "$ORIG_CC" in
    gcc|*-gcc|*/gcc)
      ASPP="$autodetect_compiler_CC -c" # include -m32 by using $CC
      ;;
  esac
  case "${DKML_COMPILE_CM_CMAKE_C_COMPILER_ID:-}" in
    AppleClang|Clang)
      # Clang Integrated Assembler
      # --------------------------
      #
      # Clang has an integrated assembler that will can be invoked indirectly (`clang --target xxx -c something.s`)
      # or directly (`clang -cc1as -help`). Calling with the `cc1as` form directly is rarely a good idea because the
      # `--target` form can inject a lot of useful default options when it itself calls `clang -cc1as <options-for-target>`.
      #
      # The integrated assembler is not strictly compatible with GNU `as` even though it recognizes GNU assembly syntax.
      # For OCaml the problem is that the integrated assembler will "error: invalid symbol redefinition" on OCaml native
      # generated assembly code like:
      #   .L108:
      #   .L108:
      # 	  bl	camlCamlinternalFormatBasics__entry(PLT)
      # Until those bugs are fixed we can't use clang for native generated code (the `AS` ./configure variable). However
      # clang can be used for the assembly code in the runtime library (the `ASPP` ./configure variable) since that assembly
      # code is hand-crafted and also because the clang integrated assembler has a preprocessor.

      # Android NDK
      # -----------
      #
      # Android NDK comes with a) a Clang compiler and b) a GNU AS assembler and c) sometimes a YASM assembler
      # in its bin folder
      # (ex. ndk/23.1.7779620/toolchains/llvm/prebuilt/linux-x86_64/bin/{clang,arm-linux-androideabi-as,yasm}).
      # The Android NDK toolchain used within CMake will select the Clang compiler as its CMAKE_ASM_COMPILER.
      #
      # The GNU AS assembler (https://sourceware.org/binutils/docs/as/index.html) does not support preprocessing
      # so it cannot be used as the `ASPP` ./configure variable.
      
      # XCode (macOS/iOS)
      # -----------------
      #
      # Nothing will be found in the code below that searches for a `<triple>-as` assembler. macOS uses
      # `AS=as -arch <target>` to select the architecture, and AS will have already been set with
      # autodetect_compiler_darwin().

      # Triples
      # -------
      #
      # Android NDK for example exposes a triple like so: CMAKE_ANDROID_ARCH_TRIPLE=arm-linux-androideabi
      # It also has the same triple in CMAKE_LIBRARY_ARCHITECTURE.
      # Other toolchains may support it as well; CMAKE_LIBRARY_ARCHITECTURE is poorly documented, but
      # https://lldb.llvm.org/resources/build.html indicates it is typically set to the architecture triple

      # Find GNU AS assembler named `<triple>-as`, if any
      #
      #   Nothing should be found in this code section if you are using an Xcode toolchain. macOS uses
      #   `AS=as -arch <target>` to select the architecture, and AS will have already been set with
      #   autodetect_compiler_darwin().
      _c_compiler_bindir=$(PATH=/usr/bin:/bin dirname "$DKML_COMPILE_CM_CMAKE_C_COMPILER")
      _gnu_as_compiler=
      for _compiler_triple in "${DKML_COMPILE_CM_CMAKE_ANDROID_ARCH_TRIPLE:-}" "${DKML_COMPILE_CM_CMAKE_LIBRARY_ARCHITECTURE:-}"; do
        if [ -n "$_compiler_triple" ]; then
          if [ -e "$_c_compiler_bindir/$_compiler_triple-as.exe" ]; then
            _gnu_as_compiler="$_c_compiler_bindir/$_compiler_triple-as.exe"
            break
          elif [ -e "$_c_compiler_bindir/$_compiler_triple-as" ]; then
            _gnu_as_compiler="$_c_compiler_bindir/$_compiler_triple-as"
            break
          fi
        fi
      done
      if [ -n "$_gnu_as_compiler" ]; then
        # Found GNU AS assembler
        if [ -x /usr/bin/cygpath ]; then
          _gnu_as_compiler=$(/usr/bin/cygpath -am "$_gnu_as_compiler")
        fi
        autodetect_compiler_AS="$_gnu_as_compiler"
        ASPP="$DKML_COMPILE_CM_CMAKE_C_COMPILER ${DKML_COMPILE_CM_CMAKE_C_COMPILE_OPTIONS_TARGET:-}${DKML_COMPILE_CM_CMAKE_C_COMPILER_TARGET:-} ${autodetect_compiler_CFLAGS:-} -c"
        if [ "${DKML_COMPILE_CM_CONFIG:-}" = "Debug" ]; then
          autodetect_compiler_AS="$autodetect_compiler_AS -g"
          # CFLAGS will already include `-g` if the toolchain wanted it.
          # But we add -fdebug-macro since there are very useful macros in the runtime code (ex. runtime/arm.S) that should be expanded when in disassembly
          # or in lldb/gdb debugger.
          ASPP="$ASPP -fdebug-macro"
        fi
      fi
      ;;
  esac
fi

# https://github.com/ocaml/ocaml/blob/01c6f16cc69ce1d8cf157e66d5702fadaa18d247/configure#L3434-L3534
# https://github.com/ocaml/ocaml/blob/01c6f16cc69ce1d8cf157e66d5702fadaa18d247/configure.ac#L1158-L1175
#
# OCaml uses LDFLAGS for both $CC (ex. gcc) and $LD, so we have to zero out
# LDFLAGS and push LDFLAGS into LD directly
if [ "${DKML_COMPILE_CM_CMAKE_SYSTEM_NAME:-}" = "Android" ]; then
  #   For Android we'll use clang for the linker which is what the recommended options in
  #   https://developer.android.com/ndk/guides/standalone_toolchain#building_open_source_projects_using_standalone_toolchains
  #   imply. Also we get CMAKE_C_LINK_OPTIONS_PIE so C compiler is best (no equivalent
  #   CMAKE_LINKER_OPTIONS_PIE variable for the standalone linker)
  autodetect_compiler_LD="$DKML_COMPILE_CM_CMAKE_C_COMPILER"
  if [ -n "${DKML_COMPILE_CM_CMAKE_C_COMPILER_TARGET:-}" ]; then
    autodetect_compiler_LD="$autodetect_compiler_LD${DKML_COMPILE_CM_CMAKE_C_COMPILE_OPTIONS_TARGET:+ $DKML_COMPILE_CM_CMAKE_C_COMPILE_OPTIONS_TARGET}${DKML_COMPILE_CM_CMAKE_C_COMPILER_TARGET:-}"
  fi
  if [ -n "${DKML_COMPILE_CM_CMAKE_SYSROOT:-}" ]; then
    autodetect_compiler_LD="$autodetect_compiler_LD${DKML_COMPILE_CM_CMAKE_C_COMPILE_OPTIONS_SYSROOT:+ $DKML_COMPILE_CM_CMAKE_C_COMPILE_OPTIONS_SYSROOT}${DKML_COMPILE_CM_CMAKE_SYSROOT:-}"
  fi
  #   Translate `-fPIE;-pie` into `-fPIE -pie`
  autodetect_compiler_LD=$(printf "%s\n" "$autodetect_compiler_LD${DKML_COMPILE_CM_CMAKE_C_LINK_OPTIONS_PIE:+ $DKML_COMPILE_CM_CMAKE_C_LINK_OPTIONS_PIE}" | PATH=/usr/bin:/bin sed 's/;/ /g')
  #   Since we are using clang as the linker, we need to prefix every word in LDFLAGS with -Wl, to pass it to linker
  for _ldflag in ${autodetect_compiler_LDFLAGS:-}; do
    autodetect_compiler_LD="$autodetect_compiler_LD -Wl,$_ldflag"
  done
  autodetect_compiler_LDFLAGS=
  #   DIRECT_LD is used by ./configure to create PARTIALLD, the ld -r partial linker. `-r` and `-pie` conflict, so
  #   regardless we are not using the LD logic above.
  DIRECT_LD=$DKML_COMPILE_CM_CMAKE_LINKER
elif [ -n "${DKML_COMPILE_CM_CMAKE_LINKER:-}" ]; then
  autodetect_compiler_LD="$DKML_COMPILE_CM_CMAKE_LINKER${autodetect_compiler_LDFLAGS:+ $autodetect_compiler_LDFLAGS}"
  DIRECT_LD=$DKML_COMPILE_CM_CMAKE_LINKER
  autodetect_compiler_LDFLAGS=
elif [ -n "${autodetect_compiler_LD:-}" ]; then
  autodetect_compiler_LD="$autodetect_compiler_LD${autodetect_compiler_LDFLAGS:+ $autodetect_compiler_LDFLAGS}"
  DIRECT_LD=$autodetect_compiler_LD
  autodetect_compiler_LDFLAGS=
  # Xcode linkers should use ld -arch XXXX
  case "$DKML_TARGET_ABI" in
    darwin_arm64)  autodetect_compiler_LD="$autodetect_compiler_LD -arch arm64"  ; DIRECT_LD="$DIRECT_LD -arch arm64" ;;
    darwin_x86_64) autodetect_compiler_LD="$autodetect_compiler_LD -arch x86_64" ; DIRECT_LD="$DIRECT_LD -arch x86_64" ;;
  esac
fi

# CMake: AR, STRIP, RANLIB, NM, OBJDUMP
if [ -z "${AR:-}" ] && ! cmake_flag_off "${DKML_COMPILE_CM_CMAKE_AR:-}"; then
  AR="${DKML_COMPILE_CM_CMAKE_AR:-}"
fi
if [ -z "${RANLIB:-}" ] && ! cmake_flag_off "${DKML_COMPILE_CM_CMAKE_RANLIB:-}" && ! [ "$DKML_COMPILE_CM_CMAKE_RANLIB" = : ]; then
  # On Windows CMAKE_RANLIB can be ":", which we skip over
  RANLIB="${DKML_COMPILE_CM_CMAKE_RANLIB:-}"
fi
if [ -z "${STRIP:-}" ] && ! cmake_flag_off "${DKML_COMPILE_CM_CMAKE_STRIP:-}"; then
  STRIP="${DKML_COMPILE_CM_CMAKE_STRIP:-}"
fi
if [ -z "${NM:-}" ] && ! cmake_flag_off "${DKML_COMPILE_CM_CMAKE_NM:-}"; then
  NM="${DKML_COMPILE_CM_CMAKE_NM:-}";
fi
if [ -z "${OBJDUMP:-}" ] && ! cmake_flag_off "${DKML_COMPILE_CM_CMAKE_OBJDUMP:-}"; then
  OBJDUMP="${DKML_COMPILE_CM_CMAKE_OBJDUMP:-}"
fi

# Final fixups
# ------------
# Precondition: All flags already set

if cmake_flag_on "${DKML_COMPILE_CM_MSVC:-}"; then
    # To avoid the following when /Zi or /ZI is enabled:
    #   2># major_gc.c : fatal error C1041: cannot open program database 'Z:\build\windows_x86\Debug\dksdk\system\_opam\.opam-switch\build\ocaml-variants.4.12.0+options+dkml+msvc32\runtime\vc140.pdb'; if multiple CL.EXE write to the same .PDB file, please use /FS
    # we use /FS. This slows things down, so we should only do it
    if printf "%s" "${autodetect_compiler_CFLAGS:-}" | PATH=/usr/bin:/bin grep -q "[/-]Zi"; then
        autodetect_compiler_CFLAGS="$autodetect_compiler_CFLAGS /FS"
    elif printf "%s" "${autodetect_compiler_CFLAGS:-}" | PATH=/usr/bin:/bin grep -q "[/-]ZI"; then
        autodetect_compiler_CFLAGS="$autodetect_compiler_CFLAGS /FS"
    fi

    # Always use dash (-) form of options rather than slash (/) options. Makes MSYS2 not try
    # to think the option is a filepath and try to translate it.
    autodetect_compiler_CFLAGS=$(printf "%s" "${autodetect_compiler_CFLAGS:-}" | PATH=/usr/bin:/bin sed 's# /# -#g')
    autodetect_compiler_CXXFLAGS=$(printf "%s" "${autodetect_compiler_CXXFLAGS:-}" | PATH=/usr/bin:/bin sed 's# /# -#g')
    autodetect_compiler_CC=$(printf "%s" "${autodetect_compiler_CC:-}" | PATH=/usr/bin:/bin sed 's# /# -#g')
    ASPP=$(printf "%s" "${ASPP:-}" | PATH=/usr/bin:/bin sed 's# /# -#g')
    autodetect_compiler_AS=$(printf "%s" "${autodetect_compiler_AS:-}" | PATH=/usr/bin:/bin sed 's# /# -#g')

    # Tell ./configure to not add /O2 and /MD (and future other flags) that should be chosen by CFLAGS
    CFLAGS_MSVC_SET=1

    # Add -MD or -MDd
    if [ "${DKML_COMPILE_CM_CONFIG:-}" = "Debug" ]; then
      autodetect_compiler_CFLAGS="-MDd${autodetect_compiler_CFLAGS:+ $autodetect_compiler_CFLAGS}"
    else
      autodetect_compiler_CFLAGS="-MD${autodetect_compiler_CFLAGS:+ $autodetect_compiler_CFLAGS}"
    fi
fi

# Bind non-standard variables into launcher scripts
export_binding ASPP "${ASPP:-}"
export_binding DIRECT_LD "${DIRECT_LD:-}"
export_binding CFLAGS_MSVC_SET "${CFLAGS_MSVC_SET:-}"
export_binding AR "${AR:-}"
export_binding STRIP "${STRIP:-}"
export_binding RANLIB "${RANLIB:-}"
export_binding NM "${NM:-}"
export_binding OBJDUMP "${OBJDUMP:-}"

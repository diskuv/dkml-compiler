#!/bin/sh
# ----------------------------
# Copyright 2022 Diskuv, Inc.
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
# ANDROID NDK
# -----------
#
# Environment variables
# - ANDROID_NDK - In GitHub Actions, the ANDROID_NDK_LATEST_HOME will be set.
#   You can use `echo "ANDROID_NDK=$ANDROID_NDK_LATEST_HOME" >> "$GITHUB_ENV"` to read it in one step
#   and have it available in all subsequent steps.
#   https://github.com/actions/virtual-environments/blob/996eae034625eaa62cc81ce29faa04e11fa3e6cc/images/linux/Ubuntu2004-Readme.md#environment-variables-3
#   https://github.com/actions/virtual-environments/blob/996eae034625eaa62cc81ce29faa04e11fa3e6cc/images/macos/macos-11-Readme.md#environment-variables-2
# - ANDROID_PLATFORM - The minimum API level. Defaults to 23.
#   Any of the formats listed in https://developer.android.com/ndk/guides/cmake#android_platform
#   is acceptable.
#
# ----------------------------
#
# This is a --post-transform script used by DkML's autodetect_compiler()
# function to customize compiler variables before the variables are written
# to a launcher script.
#
# Anything printed on stdout is ignored as of DkML 2.1.4.
#
# On entry autodetect_compiler() will have populated some or all of the
# following non-export variables:
#
# * DKML_HOST_ABI. Always available
# * DKML_TARGET_ABI. Always available
# * autodetect_compiler_CC
# * autodetect_compiler_CFLAGS
# * autodetect_compiler_CXX
# * autodetect_compiler_CFLAGS
# * autodetect_compiler_CXXFLAGS
# * autodetect_compiler_AS
# * autodetect_compiler_ASFLAGS
# * autodetect_compiler_LD
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
# a) find the compiler selected/validated in the DkML installation
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

# -----------------------------------------------------

set -euf

# Microsoft cl.exe and link.exe use forward slash (/) options; do not ever let MSYS2 interpret
# the forward slash and try to convert it to a Windows path.
disambiguate_filesystem_paths

# -----------------------------------------------------

# Documentation: https://developer.android.com/ndk/guides/other_build_systems

if [ -z "${ANDROID_NDK:-}" ]; then
    printf "FATAL: The ANDROID_NDK environment variable has not been defined. It is ordinarily set on macOS and Linux GitHub Actions hosts.\n" >&2
    exit 107
fi

#   Minimum API level
#       The default is 23 but you can override it with the environment
#       variable ANDROID_PLATFORM.
#   https://developer.android.com/ndk/guides/cmake#android_platform
#   https://apilevels.com/
ANDROID_PLATFORM=${ANDROID_PLATFORM:-}
ANDROID_PLATFORM=${ANDROID_PLATFORM##android-} # Remove any android- prefix
case "${ANDROID_PLATFORM:-}" in
    # > Jetpack/AndroidX libraries require a minSdk of 19 or higher since October 2023.
    19|KITKAT) MIN_API_LEVEL=19;;
    20|KITKAT_WATCH) MIN_API_LEVEL=20;;
    21|LOLLIPOP|L) MIN_API_LEVEL=21;;
    22|LOLLIPOP_MR1) MIN_API_LEVEL=22;;
    23|M) MIN_API_LEVEL=23;;
    24|N) MIN_API_LEVEL=24;;
    25|N_MR1) MIN_API_LEVEL=25;;
    26|O) MIN_API_LEVEL=26;;
    27|O_MR1) MIN_API_LEVEL=27;;
    28|P) MIN_API_LEVEL=28;;
    29|Q) MIN_API_LEVEL=29;;
    30|R) MIN_API_LEVEL=30;;
    31|S) MIN_API_LEVEL=31;;
    32|S_V2) MIN_API_LEVEL=32;;
    33|TIRAMISU) MIN_API_LEVEL=33;;
    34|UPSIDE_DOWN_CAKE) MIN_API_LEVEL=34;;
    35|VANILLA_ICE_CREAM) MIN_API_LEVEL=35;;
    36) MIN_API_LEVEL=36;;
    37) MIN_API_LEVEL=37;;
    38) MIN_API_LEVEL=38;;
    39) MIN_API_LEVEL=39;;
    *) MIN_API_LEVEL=23
esac

#   Toolchain
case "$DKML_HOST_ABI" in
    # HOST_TAG in https://developer.android.com/ndk/guides/other_build_systems#overview
    darwin_x86_64|darwin_arm64) HOST_TAG=darwin-x86_64 ;;
    #   NDK 27 and probably earlier do not bundle prebuilt/linux-x86 into their NDK.
    linux_x86|linux_x86_64)     HOST_TAG=linux-x86_64 ;;
    *)
        printf "FATAL: The host ABI %s does not have a Android Studio toolchain\n" "$DKML_HOST_ABI"
        exit 107
esac
TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/$HOST_TAG

#   Triple
case "$DKML_TARGET_ABI" in
    # TOOLCHAIN_NAME_CLANG 'Triple' in https://developer.android.com/ndk/guides/other_build_systems#overview
    # TOOLCHAIN_NAME_AS     https://chromium.googlesource.com/android_ndk/+/401019bf85744311b26c88ced255cd53401af8b7/build/core/toolchains/aarch64-linux-android-clang/setup.mk#16
    # LLVM_TRIPLE           https://chromium.googlesource.com/android_ndk/+/401019bf85744311b26c88ced255cd53401af8b7/build/core/toolchains/aarch64-linux-android-clang/setup.mk#17
    android_arm64v8a) TOOLCHAIN_NAME_CLANG=aarch64-linux-android ;    TOOLCHAIN_NAME_AS=aarch64-linux-android ; LLVM_TRIPLE=aarch64-none-linux-android ;;
    android_arm32v7a) TOOLCHAIN_NAME_CLANG=armv7a-linux-androideabi ; TOOLCHAIN_NAME_AS=arm-linux-androideabi ; LLVM_TRIPLE=armv7-none-linux-androideabi ;;
    android_x86)      TOOLCHAIN_NAME_CLANG=i686-linux-android ;       TOOLCHAIN_NAME_AS=i686-linux-android ;    LLVM_TRIPLE=i686-none-linux-android;;
    android_x86_64)   TOOLCHAIN_NAME_CLANG=x86_64-linux-android ;     TOOLCHAIN_NAME_AS=x86_64-linux-android ;  LLVM_TRIPLE=x86_64-none-linux-android ;;
    *)
        printf "FATAL: The DKML_TARGET_ABI must be an DkML Android ABI, not %s\n" "$DKML_TARGET_ABI" >&2
        exit 107
        ;;
esac

#   Exports necessary for OCaml's ./configure
#       https://developer.android.com/ndk/guides/other_build_systems#autoconf
find "$TOOLCHAIN/bin" -type f -name '*-clang' >&2   # Show API versions for debugging
find "$TOOLCHAIN/bin" -type f -name '*-as' >&2      # More debugging
#       Dump of Android NDK r23 flags. And -g3 and -g for debugging.
_android_common_flags="-fPIE -fPIC -no-canonical-prefixes -Wformat -Werror=format-security -g3 -g"
_android_cflags="$_android_common_flags -DANDROID -fdata-sections -ffunction-sections -funwind-tables -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fexceptions -fno-limit-debug-info"
AR="$TOOLCHAIN/bin/llvm-ar"
autodetect_compiler_CC="$TOOLCHAIN/bin/${TOOLCHAIN_NAME_CLANG}${MIN_API_LEVEL}-clang"
! [ -x "$autodetect_compiler_CC" ] && printf "FATAL: No clang compiler at %s\n" "$autodetect_compiler_CC" >&2 && exit 107
autodetect_compiler_LD="$TOOLCHAIN/bin/ld"
DIRECT_LD="$autodetect_compiler_LD"
RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
STRIP="$TOOLCHAIN/bin/llvm-strip"
NM="$TOOLCHAIN/bin/llvm-nm"
OBJDUMP="$TOOLCHAIN/bin/llvm-objdump"
#   shellcheck disable=SC2034
autodetect_compiler_CFLAGS="$_android_cflags"
#   shellcheck disable=SC2034
autodetect_compiler_LDFLAGS=
#       Android NDK comes with a) a Clang compiler and b) a GNU AS assembler and c) sometimes a YASM assembler
#       in its bin folder
#       (ex. ndk/23.1.7779620/toolchains/llvm/prebuilt/linux-x86_64/bin/{clang,arm-linux-androideabi-as,yasm}).
#
#       The GNU AS assembler (https://sourceware.org/binutils/docs/as/index.html) does not support preprocessing
#       so it cannot be used as the `ASPP` ./configure variable.
#
#       But ... NDK 24 dropped the GNU AS assembler:
#           https://github.com/android/ndk/wiki/Changelog-r24
#           https://android.googlesource.com/platform/ndk/+/master/docs/ClangMigration.md#assembler-issues
#
#       So when missing the GNU AS assembler (ie. NDK 24+) just use the ASPP.
ASPP="$TOOLCHAIN/bin/clang --target=${LLVM_TRIPLE}${MIN_API_LEVEL} $_android_common_flags -c"
autodetect_compiler_AS="$TOOLCHAIN/bin/$TOOLCHAIN_NAME_AS-as"
if [ ! -x "$autodetect_compiler_AS" ]; then
    autodetect_compiler_AS="$ASPP"
fi

# Bind non-standard variables into launcher scripts
export_binding ASPP "$ASPP"
export_binding DIRECT_LD "${DIRECT_LD:-}"
export_binding AR "${AR:-}"
export_binding STRIP "${STRIP:-}"
export_binding RANLIB "${RANLIB:-}"
export_binding NM "${NM:-}"
export_binding OBJDUMP "${OBJDUMP:-}"

# The [export_binding] and the [autodetect_compiler_*] variables will be read by
# dkml-runtime-common's crossplatform-functions.sh:autodetect_compiler_write_output()

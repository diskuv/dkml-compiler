# dkml-compiler

POSIX Bourne shell scripts to compile the DkML distribution of OCaml.

The OCaml patches in [src/p](src/p) are dual-licensed under the [OCaml flavor of the LGPL 2.1 license](./LICENSE-LGPL21-ocaml)
and the permissive [Apache 2.0 license](./LICENSE-Apache2).
All other source code including the shell scripts are released solely under the permissive [Apache 2.0 license](./LICENSE-Apache2).

There is also a `dkml-base-compiler.opam` that always compiles the latest
DkML supported compiler. However you can choose an older version by
adding an older version of [diskuv-opam-repository](https://github.com/diskuv/diskuv-opam-repository#readme)
to your Opam switch.

The `diskuv-opam-repository` is also necessary if you want to use a DkML
version of the OCaml 4.x compiler on a non-Windows machine. The central Opam
repository only introduced the DkML distribution in OCaml 5.x generally and
OCaml 4.14 for Windows specifically.

## Quick Start

### Android Cross-Compiler

NOTE 1: There are a couple major patches done by DkML to the OCaml compiler to support Android 32-bit. And the cross-compiler support is not standard (or supported) in the official OCaml compiler. Do not expect to replicate these instructions using the generic OCaml compiler.

NOTE 2: We'll use a Docker container for convenience with Windows and macOS users, and also because it is easy to get the Android NDK from CircleCI, but you can do this directly on a Linux machine.

NOTE 3: Since Apple Silicon does not support 32-bit, and since cross-compiling OCaml requires the same bitness
for the build machine and the target machine, Apple Silicon users cannot compile [Android `armeabi-v7a`](https://developer.android.com/ndk/guides/abis)
(aka. DkML `android_arm32v7a`).

```console
$ docker run -it --rm cimg/android:2024.10.1-ndk

# Install opam if you don't have it
circleci:~/project$ sudo apt-get update && sudo apt-get install build-essential curl git patch rsync unzip -y
circleci:~/project$ echo /usr/local/bin | sudo bash -c "sh <(curl -fsSL https://opam.ocaml.org/install.sh) --version 2.2.1"

# Initialize opam if you haven't already. No sandboxing is needed in containers.
circleci:~/project$ opam init --cli=2.1 --no-setup --bare --disable-sandboxing

# Two Android options to set. ANDROID_PLATFORM is the minimum API level ("targetSdkVersion" in the Android manifest)
circleci:~/project$ opam var --cli=2.1 --global ANDROID_NDK=/home/circleci/android-sdk/ndk/27.1.12297006
circleci:~/project$ opam var --cli=2.1 --global ANDROID_PLATFORM=android-34

# PICK ONE: Android arm64-v8a switch
circleci:~/project$ opam switch create android34-ndk27-arm64-v8a --cli=2.1 \
  --packages dkml-base-compiler,dkml-host-abi-linux_x86_64,dkml-target-abi-android_arm64v8a,ocamlfind,conf-dkml-cross-toolchain \
  --repos default,diskuv-4d79e732=git+https://github.com/diskuv/diskuv-opam-repository.git#4d79e732

# PICK ONE: Android armeabi-v7a switch. You will need a 32-bit C/C++ compiler.
circleci:~/project$ sudo apt-get install gcc-multilib g++-multilib -y
circleci:~/project$ opam switch create android34-ndk27-armeabi-v7a --cli=2.1 \
  --packages dkml-base-compiler,dkml-host-abi-linux_x86,dkml-target-abi-android_arm32v7a,ocamlfind,conf-dkml-cross-toolchain \
  --repos default,diskuv-4d79e732=git+https://github.com/diskuv/diskuv-opam-repository.git#4d79e732

# PICK ONE: Android x86_64 switch
circleci:~/project$ opam switch create android34-ndk27-x86_64 --cli=2.1 \
  --packages dkml-base-compiler,dkml-host-abi-linux_x86_64,dkml-target-abi-android_x86_64,ocamlfind,conf-dkml-cross-toolchain \
  --repos default,diskuv-4d79e732=git+https://github.com/diskuv/diskuv-opam-repository.git#4d79e732

# THEN: Get and cross-compile your source code. Here we use Dune and assume 'android34-ndk27-arm64-v8a'
circleci:~/project$ opam install --cli=2.1 --switch android34-ndk27-arm64-v8a dune
circleci:~/project$ git clone https://github.com/avsm/hello-world-action-ocaml hello
circleci:~/project$ cd hello
circleci:~/project/hello$ opam exec --cli=2.1 --switch android34-ndk27-arm64-v8a -- dune build -x android_arm64v8a world.exe
circleci:~/project/hello$ file _build/default*/world.exe
_build/default.android_arm64v8a/world.exe: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /system/bin/linker64, with debug_info, not stripped
_build/default/world.exe:                  ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=1731ad9ce0fdeff69df28af0b1217e843eabe26e, for GNU/Linux 3.2.0, with debug_info, not stripped

# You can also directly use the ocamlfind -toolchain
circleci:~/project$ opam exec --cli=2.1 --switch android34-ndk27-arm64-v8a -- ocamlfind ocamlc -config-var native_c_compiler
gcc -O2 -fno-strict-aliasing -fwrapv -pthread -fPIC  -D_FILE_OFFSET_BITS=64
circleci:~/project$ opam exec --cli=2.1 --switch android34-ndk27-arm64-v8a -- ocamlfind -toolchain android_arm64v8a ocamlc -config-var native_c_compiler
/home/circleci/android-sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android34-clang -O2 -fno-strict-aliasing -fwrapv -pthread -fPIC  -D_FILE_OFFSET_BITS=64
```

DkML supports three out of the four supported Android ABIs.
The three ABIs (all but `x86`) were chosen based on [statistics for a large game on Aug 29, 2023](https://github.com/android/ndk/issues/1772#issuecomment-1697831518):

| Arch        | Percent |
| ----------- | ------- |
| arm64-v8a   | 68.66   |
| armeabi-v7a | 30.38   |
| x86_64      | 0.71    |
| x86         | 0.26    |

and also [Google's recommendation](https://android-developers.googleblog.com/2022/10/64-bit-only-devices.html):

> **Note**: While 64-bit-only devices will grow in popularity with phones joining Android Auto in this group, 32-bit-only devices will continue to be important for Android Go, Android TV, and Android Wear. Please continue supporting 32-bit ABIs; Google Play will continue serving 32-bit apps to 32-bit-only devices.

---

Finally, a word of **CAUTION**. The Android cross-compiler **can never** use OCaml 5+ because [OCaml 5 will never bring back the 32-bit instruction set](https://discuss.ocaml.org/t/32-bit-native-code-support-for-ocaml-5/12583/13?u=jbeckford). That means if you don't want to drop a large percent of your users or drop new Android categories over the next five (?) years, you will have a critical dependency on DkML.

## Directory Structure

### Build Directories

| Path                               | Description                                                        |
| ---------------------------------- | ------------------------------------------------------------------ |
| `dl/*.tar.gz`                      | Opam extra-source downloads                                        |
| `dl/ocaml`                         | Unpatched OCaml source from `dl/ocaml.tar.gz`                      |
| `dl/ocaml/flexdll`                 | Unpatched flexdll source from `dl/flexdll.tar.gz`                  |
| `dkmldir/.dkmlroot`                | Properties file with the version of DkML based on the Opam version |
| `dkmldir/vendor/dkml-compiler/src` | A copy of the toplevel `src/`                                      |
| `dkmldir/vendor/drc`               | Source from `dl/dkml-runtime-common.tar.gz`                        |

### Opam Directories

| Path                                                                  | Description                                 |
| --------------------------------------------------------------------- | ------------------------------------------- |
| `$(opam var prefix)/src-ocaml`                                        | OCaml source patched for the host ABI       |
| `$(opam var prefix)/bin`                                              | OCaml host ABI binaries. Ex. `ocamlopt`     |
| `$(opam var prefix)/lib/ocaml`                                        | OCaml host ABI libraries. Ex. `unix.cmxa`   |
| `$(opam var prefix)/share/dkml-base-compiler/mlcross/<ABI>/src-ocaml` | OCaml source patched for the target ABI     |
| `$(opam var prefix)/share/dkml-base-compiler/mlcross/<ABI>/bin`       | OCaml target ABI binaries. Ex. `ocamlopt`   |
| `$(opam var prefix)/share/dkml-base-compiler/mlcross/<ABI>/lib/ocaml` | OCaml target ABI libraries. Ex. `unix.cmxa` |

All ABI names are compatible with [dkml-c-probe](https://github.com/diskuv/dkml-c-probe#readme).
The target ABI folders will not be present if DkML does not support cross-compiling
on the host ABI. Currently only macOS has a target ABI.

There is another Opam package [conf-dkml-cross-toolchain](https://github.com/diskuv/conf-dkml-cross-toolchain)
that can take the "mlcross" Opam directory structure and add it to
`findlib` so that `ocamlfind -toolchain <ABI>` and `dune build -x <ABI>` work.

## Options

### ocaml-option-bytecode-only

Builds the bytecode compiler and bytecode libraries.

### ocaml-option-address-sanitizer

The clang/gcc Address Sanitizer.

To avoid stalls seen in WSL 2 (6.6.87.2-microsoft-standard-WSL2) Debian 11.6 it is not used during the `./configure` phase but when executables are being created in the `make` phase.

On some machines you may see an endless stream of:

```text
AddressSanitizer:DEADLYSIGNAL
```

The solution is at https://github.com/actions/runner-images/issues/9524#issuecomment-2002475952 ... do the following:

```sh
sudo sysctl vm.mmap_rnd_bits=28
```

### ocaml-option-leak-sanitizer

The clang/gcc Leak Sanitizer.

To avoid stalls seen in WSL 2 (6.6.87.2-microsoft-standard-WSL2) Debian 11.6 it is not used during the `./configure` phase but when executables are being created in the `make` phase.

## Developing

First run `with-dkml make local-install` on DkML on Windows, or
`make local-install` on other platforms, to install the compiler in
a local opam switch using an in-place build.

As a useful side-effect, the in-place build recreates the
[build directories](#build-directories) that `dkml-base-compiler.opam`
assembles. Even if the `make local-install` fails to build a working OCaml
compiler, you still have all the directories ready for local development.

More developer documentation is in [DEVELOPING.md](./DEVELOPING.md).

### Patching

In what follows, `VER` is a placeholder for the OCaml major version (ex. `4`)
*and* for the OCaml major+minor version in underscore formatting (ex. `4_12`).
The major version patches are applied first, and then the major+minor version
patches are applied.

The patches are all available in `src/p/`.

* The OCaml source patched for the host ABI uses `ocaml-common-VER-*.patch` in lexographical order
  and `ocaml-host-VER-*.patch` in lexographical order.
* The OCaml source patched for the target ABI uses `ocaml-common-VER-*.patch` in lexographical order
  and `ocaml-target-VER-*.patch` in lexographical order.

It is important to realize that patches are applied in a particular order, and
to structure the patches so they are more or less independent of each other.

**When you make a patch**, you should consult the [Opam directory structure table](#opam-directories)
and do a `git log` in the `OCaml source patched ...` directories. You must also run
`./dk user.reindex` in a Unix shell or PowerShell.

## Optimization

If we have a prebuilt `ocamlc.opt` for an architecture ... possibly and likely for an old version of
OCaml, it is used to save some initial bootstrapping time during `ocaml install dkml-base-compiler`.

Note that the prebuilt `ocamlc.opt` is optional. If it doesn't exist, then some extra time is spent
during `opam install`. This optionality allows for:

1. Let's `dkml-base-compiler` build in CI.
2. Then `ocamlc.opt` can be saved forever as a CI release artifact.
3. Then `ocamlc.opt` can be used for all new compiler builds by modifying the download links in
   `dkml-base-compiler.opam`.

## Status

[![Syntax check](https://github.com/diskuv/dkml-compiler/actions/workflows/syntax.yml/badge.svg)](https://github.com/diskuv/dkml-compiler/actions/workflows/syntax.yml)

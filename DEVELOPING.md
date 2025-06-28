# Developing

Everything in this document assumes you have done:

```sh
# *nix: Linux, macOS, etc.
make local-install

# Windows
dk Ml.Use -- make local-install
```

You may also add `--verbose` to the 'opam install' lines in the `Makefile`.

## Upgrading the DKML scripts

```bash
opam install ./dkml-compiler-maintain.opam --deps-only
opam upgrade dkml-workflows

# Regenerate the DKML workflow scaffolding
opam exec -- generate-setup-dkml-scaffold
opam exec -- dune build '@gen-dkml' --auto-promote
```

## Upgrading binary assets

1. Make a `-prep` tag, and then wait for the CI to complete successfully
2. Update `src/version.semver.txt`
3. Run: `dune build '@gen-opam' --auto-promote`

> TODO: This is an outdated way to do binary assets. There is an
> `DkMLPublish_PublishAssetsTarget` function in the `dkml` project
> that can upload assets each `dkml` release.
> And `DkMLBumpVersionParticipant_PlainReplace(src/version.semver.txt)` already
> updates `src/version.semver.txt`.

## Local Development

### Windows

If you have DkML installed, we recommend:

```powershell
with-dkml make local-install
```

Otherwise, run the following inside a `with-dkml bash`, Git Bash, MSYS2 or Cygwin shell:

```sh
sh scripts/mk-ocamldir.sh
sh scripts/mk-dkmldir.sh "" ""

rm -rf _build/prefix
env DKML_SKIP_DKML_INSTALLTIME_VSDEV=1 sh src/r-c-ocaml-1-setup.sh \
    -d dkmldir \
    -t "$PWD/_build/prefix" \
    -f src-ocaml \
    -v dl/ocaml \
    -z \
    -ewindows_x86_64 \
    -k vendor/dkml-compiler/env/standard-compiler-env-to-ocaml-configure-env.sh

(cd '_build/prefix' && env DKML_SKIP_DKML_INSTALLTIME_VSDEV=1 share/dkml/repro/100co/vendor/dkml-compiler/src/r-c-ocaml-2-build_host-noargs.sh)
```

### macOS

#### Apple Silicon

If you have `opam` we recommend:

```sh
make local-install
```

Otherwise:

```sh
sh scripts/mk-ocamldir.sh
sh scripts/mk-dkmldir.sh "" ""

rm -rf _build/prefix
env DKML_REPRODUCIBLE_SYSTEM_BREWFILE=./Brewfile \
    src/r-c-ocaml-1-setup.sh \
    -d dkmldir \
    -t "$PWD/_build/prefix" \
    -f src-ocaml \
    -g "$PWD/_build/prefix/share/mlcross" \
    -v dl/ocaml \
    -z \
    -edarwin_arm64 \
    -adarwin_x86_64=vendor/dkml-compiler/env/standard-compiler-env-to-ocaml-configure-env.sh \
    -k vendor/dkml-compiler/env/standard-compiler-env-to-ocaml-configure-env.sh

(cd '_build/prefix' && share/dkml/repro/100co/vendor/dkml-compiler/src/r-c-ocaml-2-build_host-noargs.sh)

(cd '_build/prefix' && DKML_BUILD_TRACE=ON DKML_BUILD_TRACE_LEVEL=2 \
    share/dkml/repro/100co/vendor/dkml-compiler/src/r-c-ocaml-3-build_cross-noargs.sh 2>&1 | \
    tee build_cross.log)
```

### Linux

```sh
sh scripts/mk-ocamldir.sh
sh scripts/mk-dkmldir.sh "" ""

# b32 ABI on 32-bit linux_x86 (ie. 32-bit bytecode)
env src/r-c-ocaml-1-setup.sh -d dkmldir -t "$PWD/_build/prefix" -f src-ocaml -v dl/ocaml -z -elinux_x86 -P ocamldebug_gcc_clang -B -k vendor/dkml-compiler/env/standard-compiler-env-to-ocaml-configure-env.sh

# bx32 ABI on 64-bit linux_x86_64 host
env src/r-c-ocaml-1-setup.sh -d dkmldir -t "$PWD/_build/prefix" -f src-ocaml -v dl/ocaml -z -elinux_x86_64 -P ocamldebug_gcc_clang -B -X -k vendor/dkml-compiler/env/standard-compiler-env-to-ocaml-configure-env.sh

(export ASAN_OPTIONS=detect_leaks=0 && cd '_build/prefix' && share/dkml/repro/100co/vendor/dkml-compiler/src/r-c-ocaml-2-build_host-noargs.sh)
```

### Android

Your host machine will need Docker. Windows as a host is fine.

FIRST, pick one of the following (for Windows prepend `dk Ml.Use --` to the `bash` line):

1. Use the Dev Container inside Visual Studio Code.
2. ```sh
   $ docker run --rm -it debian:stable-slim
   root@12b9f953b5fd:/# apt update
   root@12b9f953b5fd:/# apt-get -q install -y --no-install-recommends build-essential gcc-multilib g++-multilib git
   ```

3. ```sh
   $ docker run --rm dockcross/manylinux2014-x86  > ./dockcross-manylinux2014-x86
   $ bash dockcross-manylinux2014-x86 --args "--platform linux/386 -it" bash
   [you:/work] main(+1/-0)+ ±
   ```

4. ```sh
   $ docker run --rm dockcross/manylinux2014-x64  > ./dockcross-manylinux2014-x64
   $ dk Ml.Use -- bash dockcross-manylinux2014-x64 --args "--platform linux/amd64 -it" bash
   [you:/work] main(+1/-0)+ ±
   ```

5. ```sh
   $ docker run --rm dockcross/manylinux_2_28-x64  > ./dockcross-manylinux_2_28-x64
   $ dk Ml.Use -- bash dockcross-manylinux_2_28-x64 --args "--platform linux/amd64 -it" bash
   [you:/work] main(+1/-0)+ ±
   ```

SECOND, run the following (change the first line to `android_arm32v7a`, `android_x86_64` or `android_arm64v8a`):

```sh
TARGETABI=android_arm32v7a # You have to set this correctly
OCAMLVER=$(cat src/version.ocaml.txt | tr -d '\r')
SEMVER=$(cat src/version.semver.txt | tr -d '\r')
case $(uname -m) in
    i686) HOSTABI=linux_x86 ;;
    *) HOSTABI=linux_x86_64 ;;
esac
case "$TARGETABI" in
    android_arm32v7a) HOSTABI=linux_x86 ;;
    *) HOSTABI=linux_x86_64 ;;
esac

./dk dksdk.android.ndk.download NO_SYSTEM_PATH

sh scripts/mk-ocamldir.sh
sh scripts/mk-dkmldir.sh "" ""

src/r-c-ocaml-1-setup.sh \
    -d dkmldir \
    -t "dist-$TARGETABI-on-$HOSTABI" \
    -v "$OCAMLVER" \
    -e "$HOSTABI" \
    -a "$TARGETABI=vendor/dkml-compiler/env/android-ndk-env-to-ocaml-configure-env.sh" \
    -k vendor/dkml-compiler/env/standard-compiler-env-to-ocaml-configure-env.sh
(cd "dist-$TARGETABI-on-$HOSTABI" && share/dkml/repro/100co/vendor/dkml-compiler/src/r-c-ocaml-2-build_host-noargs.sh)
(export DKML_BUILD_TRACE=ON "ANDROID_NDK=$PWD/.ci/local/share/android-sdk/ndk/23.1.7779620" && cd "dist-$TARGETABI-on-$HOSTABI" && sh share/dkml/repro/100co/vendor/dkml-compiler/src/r-c-ocaml-3-build_cross-noargs.sh)
```

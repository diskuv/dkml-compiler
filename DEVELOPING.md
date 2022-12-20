# Developing

## Windows

You can do the following in PowerShell to build the compiler into a local switch. Make
sure you have done a `git commit` before doing the commands below:

```powershell
Remove-Item -LiteralPath _opam -Recurse

opam switch create . --empty --repos diskuv=git+https://github.com/diskuv/diskuv-opam-repository.git#main,default=https://opam.ocaml.org

#   Force an update since 'opam switch create' only updates when it newly registers the repository
opam update diskuv

opam pin add ocaml -k version 4.14.0 --no-action
opam install .\dkml-base-compiler.opam --inplace-build --keep-build-dir --yes
```

It is okay if it fails. You can do more local troubleshooting by running
the following inside a `with-dkml bash` shell:

```sh
rm -rf _build/prefix

env TOPDIR=dkmldir/vendor/drc/all/emptytop \
    DKML_REPRODUCIBLE_SYSTEM_BREWFILE=./Brewfile \
    src/r-c-ocaml-1-setup.sh \
    -d dkmldir \
    -t "$PWD/_build/prefix" \
    -f src-ocaml \
    -g "$PWD/_build/prefix/share/mlcross" \
    -v dl/ocaml \
    -z \
    -ewindows_x86_64 \
    -k vendor/dkml-compiler/env/standard-compiler-env-to-ocaml-configure-env.sh

(cd '_build/prefix' && share/dkml/repro/100co/vendor/dkml-compiler/src/r-c-ocaml-2-build_host-noargs.sh)
```

## macOS

### Apple Silicon

```sh
make local-install
```

It is okay if it fails. You can do more local troubleshooting with:

```sh
rm -rf _build/prefix

env TOPDIR=dkmldir/vendor/drc/all/emptytop \
    DKML_REPRODUCIBLE_SYSTEM_BREWFILE=./Brewfile \
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
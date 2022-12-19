# Developing

## Windows

You can do the following in PowerShell to build the compiler into a local switch. Make
sure you have done a `git commit` before doing the commands below:

```powershell
Remove-Item -LiteralPath _opam -Recurse
opam switch create . --empty --repo diskuv=git+https://github.com/diskuv/diskuv-opam-repository.git#main,default=https://opam.ocaml.org
opam pin add ocaml -k version 4.14.0 --no-action
opam install . --yes
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
    dkmldir/vendor/dkml-compiler/src/r-c-ocaml-1-setup.sh \
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
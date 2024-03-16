# Developing

Everything in this document assumes you have done:

```sh
# *nix: Linux, macOS, etc.
make local-install

# Windows
with-dkml make local-install
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

Otherwise, run the following inside a `with-dkml bash`, MSYS2 or Cygwin shell:

```sh
rm -rf _build/prefix

env DKML_REPRODUCIBLE_SYSTEM_BREWFILE=./Brewfile \
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

### macOS

#### Apple Silicon

If you have `opam` we recommend:

```sh
make local-install
```

Otherwise:

```sh
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

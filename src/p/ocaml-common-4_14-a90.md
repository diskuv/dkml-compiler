# a90

Diff of the pre-generated `configure` script from the
[dra27 relocatable base commit](https://github.com/dra27/ocaml/commit/5fe7f0fbcb)
(`5fe7f0fbcb` — OCaml 4.14.3+relocatable version bump) to the
[dra27 relocatable fork final commit](https://github.com/dra27/ocaml/tree/8b8971e46f5c09aedb5f8d43a6e2701fecc8f98d)
(`8b8971e46f5c09aedb5f8d43a6e2701fecc8f98d`).

OCaml's build system uses the pre-generated `configure` script directly without
re-running `autoconf`.  Patches `a01`–`a89` update `configure.ac` but not
`configure`, so the relocatability options they introduce
(`--enable-runtime-search`, `--with-relative-libdir`, etc.) would otherwise be
silently ignored at configure time.  This patch closes that gap.

**Why the base is `5fe7f0fbcb` (not vanilla 4.14.3):**
Patch `a01` is a cherry-pick of `5fe7f0fbcb`, the dra27 "base version" commit.
It updates the version string `4.14.3` → `4.14.3+relocatable` in both
`configure.ac` and `configure` using a binary delta.  Generating `a90` from
vanilla 4.14.3 would cause a conflict with the version-string hunk already
applied by `a01`, so `a90` must start from the post-`a01` state.

## Verification

Running `autoconf` on OCaml 4.14.3 `configure.ac` with all `a01`–`a89`
`configure.ac` changes applied (using Debian Bullseye autoconf 2.69) produces a
`configure` script whose relocatability logic is identical to the one produced
by applying `a90` to the vanilla 4.14.3 `configure` (33/33 option occurrences
match).

The only two non-functional differences between the autoconf output and the
`a90`-patched configure are:

1. **dra27 git-config preamble** — a developer convenience block that dra27
   maintains manually at the top of `configure` (not generated from
   `configure.ac`).  It allows `git config ocaml.configure` to inject extra
   configure options automatically.  It is harmless during DkML builds because
   builds do not run inside a git repository.

2. **`runstatedir` variable** — present in Debian Bullseye's autoconf 2.69
   packaging but absent from the autoconf 2.69 used in dra27's build
   environment.  It is an unused standard directory variable unrelated to
   relocatability.

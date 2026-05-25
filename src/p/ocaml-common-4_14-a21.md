# a21

Commit: 6748637a898c6e0a6999dae470d64702f571059b

Message:

```text
Add a configurable library directory on target

Add a `TARGET_LIBDIR` variable to `configure` and assign a Makefile
`TARGET_LIBDIR` variable with it
Use the value of `LIBDIR` by default for this new variable
Use `TARGET_LIBDIR` to define the `OCAML_STDLIB_DIR` macro used by the
runtime

When building a cross compiler, the OCaml standard library has no reason
to be found at the same paths on the host and on the target. This allows
users to provide a path that is meaningful to look for libraries to link
dynamically on the target.

Deviations from original:
  - Variable introduced as an alias of LIBDIR, for convenience with
    other subsequent patches.

(cherry picked from commit 799fd8e2d0e0c250d03f5174f83d110ae5d24057)
(cherry picked from commit 8d5c1cbb2e8cd10b214ea52481a98d2c44bca705)

```

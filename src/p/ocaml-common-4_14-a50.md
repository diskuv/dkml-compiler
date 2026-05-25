# a50

Commit: 564e7d9e382db4edb9dba901eae87e94d7e58cb7

Message:

```text
Allow libdir to be found relative to bindir

When configured with --with-relative-libdir, the runtime uses the
directory of the executable to determine the location of the Standard
Library. Thus, ocamlrun and the compilers look for ../lib/ocaml by
default.

This is implemented by changing caml_standard_library_default to be a
relative path, and then computing the actual value at startup (for
bytecode) and when queried (for native).

Executables (and objects) produced by the compiler always have an
absolute value of caml_standard_library_default. ocamlc.opt and
ocamlopt.opt are built using -set-runtime-default to force
caml_standard_library_default to be a relative value.

(cherry picked from commit 205bab8a0d62ddb6ff357de719e5e57406de8745)

```

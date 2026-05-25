# a64

Commit: 50715a3437bdb8887e5da6826adf42bd84025390

Message:

```text
Build suffixed shared runtimes

New names for libcamlrun_shared.so and libasmrun_shared.so without the
_shared suffix and using the target triplet and runtime ID. Both ocamlc
and ocamlopt explicitly recognise `-runtime-variant _shared` and select
the correct name.

Symbolic links for libcamlrun_shared.so and libasmrun_shared.so to allow
any C programs which linked against the the output of `-output-obj` to
continue to work.

(cherry picked from commit 0f87c767fad3c962a5d8b5809f84d50f0e7b6c43)

```

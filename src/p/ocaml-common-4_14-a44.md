# a44

Commit: 7e8165a7f8567877b11ef45d953c62d093388353

Message:

```text
Add caml_runtime_standard_library_default

Previously, the bytecode runtime just used OCAML_STDLIB_DIR from
build_config.h. This value is now stored once in dynlink.o as
caml_runtime_standard_library_default.

(cherry picked from commit b3eaa24cf884bcb97a428add3c2aa09730073489)

```

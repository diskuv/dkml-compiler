# __declspec(dllimport)

Problem on a **64-bit** Windows machine:

```text
Fatal error: cannot load shared library dllcurl_stubs
Reason: flexdll error: cannot relocate Caml_state RELOC_REL32, target is too far: FFFFFFFF2DAA3206  000000002DAA3206
```

Confer <https://github.com/ocaml/ocaml/pull/10351#issuecomment-821957197> for the problem and solution.

This patch will add `__declspec(dllimport)` to `Caml_state` and other OCaml globals if MSVC is the compiler.

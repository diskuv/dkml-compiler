# ocamlsrcdir

The Windows 4.14.3 build needed a fix because `ocamltest_config.ml.in` has` %%ocamlsrcdir%%` when
ocamltest_config.mlp.in was meant to be used, which made backslash-heavy build paths fail with illegal OCaml string escapes.

The fix switches that field to an OCaml raw string literal so Windows source-tree paths can be substituted without escaping.

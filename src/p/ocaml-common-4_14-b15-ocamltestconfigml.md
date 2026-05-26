# ocamltest config output

The Windows 4.14.3 build needed a fix because `configure` was taught to generate `ocamltest/ocamltest_config.mlp` even though the OCaml source tree and later patches still use `ocamltest_config.ml.in`. The fix changes the generated file back to `ocamltest/ocamltest_config.ml` in both `configure.ac` and the shipped `configure` script so config.status matches the real build rules.

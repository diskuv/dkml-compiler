The Windows 4.14.3 patch stack still needs this configure fix because `config.status` asks for `ocamltest/ocamltest_config.mlp` while the tree ships `ocamltest_config.ml.in`.
The fix changes both `configure.ac` and the generated `configure` script to generate `ocamltest/ocamltest_config.ml`, which matches the source template that already exists.

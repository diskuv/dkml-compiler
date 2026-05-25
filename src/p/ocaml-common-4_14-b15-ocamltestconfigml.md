# ocamltestconfigml

Problem: `config.status` needs `ocamltest/ocamltest_config.mlp` while the source code has `ocamltest_config.ml.in`.

Fix: `configure.ac` (ie. `configure`) generates `ocamltest/ocamltest_config.ml` not `.mlp`

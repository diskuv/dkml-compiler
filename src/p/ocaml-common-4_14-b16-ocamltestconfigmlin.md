# ocamltest config intermediate

The Windows 4.14.3 build needed a fix because `config.status` was generating `ocamltest_config.ml` directly, which left raw `%%...%%` placeholders like `%%AFL_INSTRUMENT%%` and made `ocamltest_config.ml` fail to parse. The fix changes `configure` and `configure.ac` to generate `ocamltest_config.ml.in` instead so the existing `Makefile` `sed` rule can perform the final placeholder substitutions.

# a37

Commit: 4af56a7443c362b2c46771cf74c1644886b6c3b1

Message:

```text
Use caml_parse_ld_conf in ocamlc

Eliminate the need for two implementations of the parsing logic for
ld.conf by sharing the C implementation (which must exist, since it's
part of bytecode startup) with the bytecode compiler, replacing
Dll.ld_conf_contents

(cherry picked from commit fe00390c147359197b1ec5c0665a1aa8a5cdb828)

```

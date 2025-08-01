# compile flags

Replaces `-O2` with `-g3 -Og`.

The use of `INJECT_CFLAGS` does not work (it does not propagate to `ocamlc -config`) on Linux/gcc.

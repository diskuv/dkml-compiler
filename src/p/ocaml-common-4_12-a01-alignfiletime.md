https://github.com/ocaml/ocaml/pull/11374

Only ported over the `ocaml/otherlibs/unix/gettimeofday_win32.c` change
since that was the only critical bug. The other changes were code
cleanup and less holding of the OCaml lock (ie. a performance improvement).

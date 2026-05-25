# a61

Commit: 68e4aa0859f05f91511213ee522d9baa3fd790a8

Message:

```text
Add -runtime-search to ocamlc

-runtime-search {disable|enable|always} adds new features to the
launcher used for bytecode executables which do not embed their own
runtime. By default, the header continues to behave as before - the
launcher will attempt to start the runtime using the absolute path which
the compiler was configured with.

The new search mode will then search for the runtime first in the
directory containing the running executable and then in PATH.

(cherry picked from commit 7b5eeb75ad8b2713938e2d0a5f04fa7d41725852)

```

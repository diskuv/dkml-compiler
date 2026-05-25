# a35

Commit: f6e0a730f49ca9b6d37d7573c9dd638fcf39c72b

Message:

```text
Remove caml_get_stdlib_location

The function was only ever added to share the logic between dynlink.c
and startup_byt.c - now that dynlink.c doesn't require it, move the
function to startup_byt.c and make it internal again.

(cherry picked from commit 98dbb3c5e1e90e35365897987a9e42de2299f2e4)

```

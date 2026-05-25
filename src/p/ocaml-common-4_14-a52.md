# a52

Commit: a895a260a10a2c9e0d61a90ee190075c6cdacb6d

Message:

```text
Detect but ignore -fdebug-prefix-map on mingw-w64

mingw-w64 is based on GCC, so supports -fdebug-prefix-map, but the test
for it is skipped in configure. The test is no longer skipped (which
means that Config.c_has_debug_prefix_map returns true) but the flag is
still explicitly not used by the compilers (as before).

(cherry picked from commit 027e314de05f7694aad65cfd6cf829e798934be3)

```

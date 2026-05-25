# a38

Commit: 977b12d6285935757f0d0372e2df9f053ba36e35

Message:

```text
Tidy installation of static builds

- $libdir/stublibs is no longer created for a --disable-shared build
- When $libdir/stublibs is not created, it is also not added to ld.conf

(cherry picked from commit 5ca89cf24dae1b24071d3f5688947d052fbf1172)

```

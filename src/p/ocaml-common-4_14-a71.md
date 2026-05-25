# a71

Commit: 5dc0c56b558d11edafa91277c68a414f4827b8c8

Message:

```text
Don't explicitly install toplevel/byte/*.cmi

All of the .mli files in toplevel/byte are "common", so they're already
installed by the patterns in toplevel.

(cherry picked from commit 1878e0441085f6908d585b58ec0177788b4720e2)

```

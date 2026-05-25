# a03

Commit: 234bdc9a2e4239cc08d60d928347ca83f0cc67c7

Message:

```text
Compute LN during configure rather than during build

On Windows, this changes the value of LN used by the root Makefile.
Indeed, before this commit the root Makefile was using cp, whereas it
now uses "cp -pf". This is better because the LN command is used
to copy/symlink files in theinstallationdirectory, so it is important that
the permissions are preserved by the operation, which a simple cp
wouldn't do, falling back to the permission inherited from the
parent directory.

(cherry picked from commit 775917d3847d1e7615599ef58dae81851fb8e197)
(cherry picked from commit c299bcb4c6ad06712072c973728697203bb55751)

```

# a40

Commit: 30d9847493a8f105b76be172a9b8e76b88fca545

Message:

```text
Fix the detection of Cygwin-like build environments

Both Cygwin and MSYS2 are now consistently detected on MSYS2. In
particular, this means that ./configure --prefix $PWD/install and
similar will cause the prefix to be correctly translated to a Windows
path, as already happens on Cygwin.

(cherry picked from commit 2c9b00528eb82f56b45c29525271c81ee0b0c16b)

```

# a08

Commit: cf54edbe2c11c4f865263a0d3b00823a5ae97a07

Message:

```text
Eliminate warning in stdlib/header.c

Newer glibc headers add __attribute__((warn_unused_result)) to write.
Switch to fputs instead for the error messages in the header program.

(cherry picked from commit 6760d9efdfa938b1f12ae4bfffaa545b6be54565)
(cherry picked from commit 13b4de4b82944fa312f8030acaaccf5bf1d39bfd)

```

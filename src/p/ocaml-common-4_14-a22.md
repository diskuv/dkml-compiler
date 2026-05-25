# a22

Commit: 3d9d9c0596faceaf204b26dd7601cb9399dea02a

Message:

```text
Fix backslashes in runtime/build_config.h

echo cannot portably be used to display strings containing backslashes
and the echo builtin in dash in particular always transforms \\ to \
which breaks the transformation in sak.

Use printf instead.

Co-authored-by: Samuel Hym <samuel@tarides.com>
(cherry picked from commit 9d3164630236aa4e6a070966b934474f5fd1a3f8)
(cherry picked from commit a442252cdeb9285772cf0207dbf87686af39d4cc)

```

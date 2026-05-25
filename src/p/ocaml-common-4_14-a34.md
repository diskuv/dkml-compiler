# a34

Commit: 9a94b5970c2f826e6901397e0718b20128398b9c

Message:

```text
Load ld.conf from all possible places

Before, the first ld.conf found from $OCAMLLIB, $CAMLLIB or the
preconfigured standard library location was loaded. Now all of these
are loaded.

(cherry picked from commit 648039dc05ae21e6b6716fb245b973d4c849ce4f)

```

# a41

Commit: adb3fbb4ff3f0d0ab3b4a15b2772ececf4dd015a

Message:

```text
Preserve backslashes in --prefix

Previously, the --prefix argument was always normalised with cygpath -m
which meant that regardless of the argument, the paths used in the
compiler would always use slashes.

This behaviour is preserved if a slash is detected in the argument, i.e.
the caller explicitly uses mixed notation (e.g. `--prefix=C:/Prefix` or
`--prefix $PWD/install`). In particular, it means that a Cygwin-style
path will be correctly converted to a Windows-style path.

If the path uses backslashes, then it is still converted to use forward
slashes for the installation commands, but the backslashes are otherwise
preserved and used within the build itself.

(cherry picked from commit 46b44c93d5891803b16f241b4b4bf0cab16414ab)

```

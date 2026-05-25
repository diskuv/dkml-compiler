# a70

Commit: 5ab739c590b6f236f947f6f4a74077560ab204de

Message:

```text
Don't install two different bigarray.mli files

Unfortunately, when installing source artefacts, the legacy bigarray
library blats its copy of bigarray.mli over the Standard Library's.
Preserve this unfortunate behaviour (since in this case bigarray.mli
corresponds with bigarray.cmti) but suppress the installation of the
Standard Library's bigarray.mli to prevent the same destination file
being used twice.

(cherry picked from commit 283aa3e58e05fd937e21f9e44fc27e82c3d65bda)

```

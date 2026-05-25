# a14

Commit: 7d069a7c3557978186cb0dea3ddabde11ebebdea

Message:

```text
Don't include the flexdll directory with -nostdlib

When FlexDLL is bootstrapped, -I +flexdll is effectively added with the
Standard Library directory. This shouldn't be done when -nostdlib is in
effect. In practice, this should only affect the build system, which is
erroneously including the _installed_ +flexdll directory when partially
linking.

(cherry picked from commit 5d0236524c240d5877b528eb9ec4468b0c1a09f9)
(cherry picked from commit ecc8900ba820a5f1582034e6da8d5b632ef3c5f4)

```

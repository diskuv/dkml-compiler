# a19

Commit: 55f3755d7a580e4c25dc92173823af8f41ddd4f2

Message:

```text
Add caml_stat_char_array_{to,of}_os

Allows conversion of arbitrary char/wchar_t sequences by allowing the
number of characters copied to be specified. The output length of the
encoding can also be returned by these functions.

Deviations from original:
  - Runtime changes made compatible with -Wdeclaration-after-statement

(cherry picked from commit 657d79eb2d4d6c3502cf49067d24980c25d2b442)
(cherry picked from commit 2db0656f1a24f3e13e23581547d77cb483462e08)

```

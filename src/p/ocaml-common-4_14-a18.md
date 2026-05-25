# a18

Commit: 13a274ca36f0142a706bdc46d36b216c6be5bdc8

Message:

```text
Correct OOM semantics of caml_stat_strdup_to_os

The Windows implementation caml_stat_strdup_to_utf16 returned NULL on
OOM, where caml_stat_strdup raises Out_of_memory. Windows implementation
fixed to raise Out_of_memory.

Deviations from original:
  - Removed definition of caml_stat_strdup_noexc_to_os from caml/misc.h
  - Implemented directly by using caml_stat_alloc

(cherry picked from commit 3adf26f4284e4f8c74cfe347565466e6572e2d22)
(cherry picked from commit e4f44b9c58cd5a3935c6bcca59316b743c6a0954)

```

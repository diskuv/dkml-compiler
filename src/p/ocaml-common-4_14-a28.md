# a28

Commit: 75e3c0604ca45bc12ff6c804d7729f6cc0f7b664

Message:

```text
Add Compmisc.reinit_path

Compmisc.init_path initialises the load path using
Config.standard_library. Compmisc.reinit_path generalises this, allowing
an alternate value for the standard library location to be used. This is
used internally when testing compiler installations in order to allow
Ccomp.call_linker to be used.

Deviations from original:
  - Paranoid implementation using Compmisc.reinit_path used instead of
    the change to Compmisc.init_path merged in OCaml 5.5

(cherry picked from commit 6b82c95cf44071e86c3cbba2757520d0c227f339)
(cherry picked from commit 5f6b3010176f2844402d824962de1b3d587b57ca)

```

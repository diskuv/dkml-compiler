# a16

Commit: 03f6ae76633630f006de8248249a46de1c46f14f

Message:

```text
Create symlinks on Windows when available

Previously Windows unconditionally uses `cp`, doubling the size required
for the OCaml binaries. `configure` now determines if `ln` creates
native symlinks and only uses `cp` if that fails. Users of the compiler
are simply required to enable Developer Mode (or build OCaml using an
elevated shell).

(cherry picked from commit b082fd17f080c7fb7e13f2bbb57edb06cd1e81c8)
(cherry picked from commit 372e5f98d1b5fd7472b776a501bbd19c341d9d95)

```

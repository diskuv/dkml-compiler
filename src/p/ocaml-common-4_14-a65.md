# a65

Commit: 36ea0b0882240e18a596b790d4ffd6fe1366feb7

Message:

```text
Add runtime suffixes to bytecode stub libraries

ocamlc -dllib-suffixed appends the runtime's host triplet and bytecode
runtime ID to the supplied name when searching for the DLL, and records
the base name only in .cma / executable files.

ocamlmklib -suffixed instructs ocamlmklib to use -dllib-suffixed when
generating .cma files instead of -dllib.

The effect is that stub libraries built this way have names which will
be unique for a given configuration of OCaml and so will be ignored by
other runtimes.

(cherry picked from commit 9a65e6841307c70f2de9208605eae36d0ef528ea)

```

# byterntm dependencies

The Windows 4.14.3 build needed a fix because `make coreall` could compile `bytecomp/byterntm.ml` before `bytecomp/byterntm.mli`, which left `byterntm.cmo` without the required `.cmi`. The fix adds explicit `Makefile` dependencies so `bytecomp/byterntm.cmo` and `bytecomp/byterntm.cmx` wait for `bytecomp/byterntm.cmi`.

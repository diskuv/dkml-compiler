# GNU as x86/x86_64 debugging

The `asmcomp/x86_gas.ml` module (used by both IA-64 and IA-32) places `.file ""` at the top
of each GNU `as` assembly source file.
That is done to create reproducible builds: <https://github.com/ocaml/ocaml/issues/7037>.

However, we get:

```text
./BOOT_OCAMLC -stdlib.s: Assembler messages:
stdlib.s:1009: Error: file number 1 already allocated
File "/work/build/DkSDKFiles/cfg-Debug/o/src/ocaml/stdlib/stdlib.ml", line 1:
Error: Assembler error, input left in file /work/build/DkSDKFiles/cfg-Debug/o/src/ocaml/stdlib/stdlib.s
make[2]: *** [stdlib.cmx] Error 2
make[1]: *** [libraryopt] Error 2
make: *** [opt-core] Error 2
FATAL: make opt-core -j6 -l6 failed
```

That is because the `.file ""` seems to be treated as an implicit file number 1,
which is re-used in:

```asm
; ...
 .globl camlStdlib__failwith_7
camlStdlib__failwith_7:
 .file 1 "stdlib.ml"
 .loc 1 29 13
; ...
.L352:
 movl %eax, %edx
 movl %edx, (%esp)
 .file 2 "camlinternalAtomic.ml"
 .loc 2 27 13
```

The patch does the following:

1. Starts the file numbering from 2, not 1.
2. Changes `.file ""` to `.file 1 ""` to avoid `Error: unassigned file number 1`.

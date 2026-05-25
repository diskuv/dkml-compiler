# native toplevel

Without the patch we get the following during `make opt.opt`:

```text
src-ocaml/support/ocamloptHost-final.wrapper -strict-sequence -principal -absname -w +a-4-9-40-41-42-44-45-48-66-70 -warn-error +a -bin-annot -safe-string -strict-formats -I utils -I parsing -I typing -I bytecomp -I file_formats -I lambda -I middle_end -I middle_end/closure -I middle_end/flambda -I middle_end/flambda/base_types -I asmcomp -I driver -I toplevel  -c toplevel/native/tophooks.ml -I toplevel/native
"...\src-ocaml\toplevel\native\tophooks.ml", line 28, characters 2-33:
28 |   Dynlink.unsafe_get_global_value ~bytecode_or_asm_symbol:sym
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error: Unbound module Dynlink
make: *** [Makefile:1132: toplevel/native/tophooks.cmx] Error 2
```

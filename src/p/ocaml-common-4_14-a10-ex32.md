# ocaml-common-4_14-a10-ex32

The `_ex32` ABI modifier sets the OCaml architecture to 32-bit while the C architecture is 64-bit.

## Why choose this ABI modifier?

1. It will always produce 32-bit bytecode compatible with the `dk` cross-compiler, `js_of_ocaml` (JS and WASM).
   In particular, `js_of_ocaml` and regular bytecode will fail with `input_value: integer too large` if the
   bytecode was compiled on a 64-bit machine and the bytecode uses 64-bit integers (ex. the constant
   `0x7fffffff00000000`):

   - https://github.com/ocaml/ocaml/blob/aaf854dfff5e2e424aa0673ae6873faa64b664bb/runtime/intern.c#L560
   - https://github.com/ocsigen/js_of_ocaml/blob/e6c8a9adf7a3cb5a3bbee21b753b6dab0a7c1c36/runtime/js/marshal.js#L360-L362
   - https://github.com/ocsigen/js_of_ocaml/blob/e6c8a9adf7a3cb5a3bbee21b753b6dab0a7c1c36/runtime/wasm/marshal.wat

2. At compile time it will give you syntax errors for 32-bit incompatibilities like the constant `0x7fffffff00000000`.

## Limits

The 32-bit OCaml architecture has limits:

* the maximum `string` length is 16 MiB (2^22-1 words; ie. `Max_wosize = (1 << 22) - 1`)
* the maximum `int` is 2GiB (2^31 bytes)

In addition, the ex32 modifications require:

* The threaded interpreter requires that the interpreter instruction opcodes are within 2GiB (a signed int distance)
  of each other. Typically instruction opcodes like `lbl_GETSTRINGCHAR` are linked together in the same segment
  since they are all defined inside interp.c. However, if you re-arrange the linker symbols or mix-and-match
  opcodes from different libraries, this 2GiB range may be violated.

But the C heap can address the 64-bit address space.

Use:

* `Int64.t`, a boxed type, to use 64-bit integers
* `Bigarray.t` to access the C heap. A single bigarray can address 2 billion (2,147,483,648) int8/uint8/float16/... items.
* If you need to address more than 2GiB (ex. 2,147,483,648 uint8), use multiple `Bigarray.t`

## How

* The OCaml `value` object is a 64-bit integer; that reflects the 64-bit C pointer size. Any tagged integers will occupy the lower 32-bits.
* The OCaml memory page table is a sparse hash table just like 64-bit OCaml.
* The C type `intnat` is 64-bit, but is serialized and deserialized as 32-bit for compatibility with 32-bit bytecode.
* The interpreter threaded mode works with 64-bit jump pointers but all interpreter opcodes must be within 31-bits (signed int distance) of each other.

This patch can't be imported directly into a conventional OCaml compiler without also:

1. Defining `TARGET_C_ARCH_SIXTYFOUR` in `runtime/caml/m.h` so the C target ABI is recognized as 64-bit.
2. Undefining `ARCH_SIXTYFOUR` in `runtime/caml/m.h`.

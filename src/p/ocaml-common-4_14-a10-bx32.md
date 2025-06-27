# ocaml-common-4_14-a10-bx32

The `bx32` ABI is the OCaml bytecode-only architecture with 32-bit OCaml types while the C architecture is 64-bit.

It reports itself with `ocamlc -config` as:

```text
int_size: 31
word_size: 64
```

For convenience we'll give names to the other ABIs in common use.

| Name  | int_size | word_size | Purpose                                              |
| ----- | -------- | --------- | ---------------------------------------------------- |
| b32   | 31       | 32        | Traditional 32-bit OCaml ABI                         |
| b64   | 63       | 64        | Traditional 64-bit OCaml ABI                         |
| bjs32 | 32       | 32        | Interop with JavaScript and WASM                     |
| bx32  | 31       | 64        | 1. High-portability of bytecode even with 64-bit PCs |
|       |          |           | 2. Access to 64-bit memory when on 64-bit PCs        |

## Problems Solved - Why bx32?

1. `bx32` will always produce 32-bit bytecode compatible with the `dk` cross-compiler and `js_of_ocaml` (JS and WASM).
   In particular, `js_of_ocaml` and regular bytecode will fail with `input_value: integer too large` if the
   bytecode was compiled on a 64-bit machine and the bytecode uses 64-bit integers (ex. the constant
   `0x7fffffff00000000`):

   - https://github.com/ocaml/ocaml/blob/aaf854dfff5e2e424aa0673ae6873faa64b664bb/runtime/intern.c#L560
   - https://github.com/ocsigen/js_of_ocaml/blob/e6c8a9adf7a3cb5a3bbee21b753b6dab0a7c1c36/runtime/js/marshal.js#L360-L362
   - https://github.com/ocsigen/js_of_ocaml/blob/e6c8a9adf7a3cb5a3bbee21b753b6dab0a7c1c36/runtime/wasm/marshal.wat
  
   Of course this problem can be avoided by compiling on a 32-bit CPU (ex. Linux x86 or Windows x86), but that is
   incredibly inconvenient and borderline impossible on Apple Silicon.

2. At compile time `bx32` will give you syntax errors for 32-bit incompatibilities like the constant `0x7fffffff00000000`.

The name `bx32` is a play on the [Linux X32 ABI](https://wiki.debian.org/X32Port), which is marginally similar in design
but is drastically different in intent (X32 is for performance, bx32 is for portability).

## Limits

The 32-bit OCaml architecture has limits:

* the maximum `string` length is 16 MiB (2^22-1 words; ie. `Max_wosize = (1 << 22) - 1`)
* the maximum `int` is 2GiB (2^31 bytes)

In addition, `bx32` has its own limits:

* The threaded interpreter requires that the interpreter instruction opcodes are within 2GiB (a signed int distance)
  of each other. Typically instruction opcodes like `lbl_GETSTRINGCHAR` are linked together in the same segment
  since they are all defined inside interp.c. However, if you re-arrange the linker symbols or mix-and-match
  opcodes from different libraries, this 2GiB range may be violated.

However, with `bx32` the C heap can address the 64-bit address space on a 64-bit PC.

So you should use:

* `Int64.t`, a boxed type, to use 64-bit integers
* `Bigarray.t` to access the C heap. A single bigarray can address 2 billion (2,147,483,648) int8/uint8/float16/... items.
* If you need to address more than 2GiB (ex. 2,147,483,648 uint8), use multiple `Bigarray.t`

### Implementation Limits

This `bx32` patch can't be imported directly into a conventional OCaml compiler without also:

1. Defining `TARGET_C_ARCH_SIXTYFOUR` in `runtime/caml/m.h` so the C target ABI is recognized as 64-bit.
2. Undefining `ARCH_SIXTYFOUR` in `runtime/caml/m.h`.

## Ecosystem Changes

Most OCaml projects ... if they support bytecode-only ... will compile without modification in a `bx32` environment.

The following projects are exceptions and have tiny patches:

| Project | Patch                                                                                 |
| ------- | ------------------------------------------------------------------------------------- |
| `base`  | https://github.com/jonahbeckford/base/commit/8e18f0b749fd60bde8889824d1c38629265f8634 |

## In-Memory Representation

### Pages

* A **page** is a 4096-byte (2^12) block of heap memory
* The **page table** is a map whose keys are the addresses of *page* and whose values are 8-bit integers. The physical representation of a key is often a page index (the address divided by 4096-byte page size).
* With `bx32` the OCaml memory page table is a sparse hash table just like `b64`.
* There is a **heap** which is a linked list of **heap chunk**s. Each heap chunk is a pointer to an aligned, append-only, bounded-memory array of [header](#header) and [value](#values) pairs, with a **head chunk header** preceding the array of *header + value* pairs. Each heap chunk is malloc'd in `memory.c:caml_alloc_for_heap()`.

### Bytecode Interpreter

* With `bx32` The interpreter threaded mode works with 64-bit jump pointers but all interpreter opcodes must be within 31-bits (signed int distance) of each other.

### Values

* A **value** is the memory representation of an OCaml variable. It will be either an **integer value** or a **pointer value**. The bx32 OCaml `value` object is a 64-bit integer; that reflects the 64-bit C pointer size. Any tagged integers will occupy the lower 32-bits.
* A **pointer value** is a pointer to the field words of the OCaml variable. For example, for an OCaml array the pointer value will be the pointer to the first element of the array, and for an OCaml string the pointer value will be the pointer to the first character of the string. Immediately preceding the field words is the 1-word header which contains, among other things, the number of field words for the OCaml variable in its `word_size` bits, and the runtime type of the OCaml variable in its 8 `tag` bits. The number of bits to encode the `word_size` is discussed in the [Header section](#header).
* A **string value** is a pointer to a null-terminated string with trailing padding that encodes the string length modulus 4 or modulus 8 on `b32` or `b64`, respectively. Immediately preceding the string is the 1-word header that contains, among other things, the word size (the string length divided by 4 or 8 in `b32` or `b64`, respectively, plus the zero or one padding word). The encoding of padding words is complex and is not relevant to this document. The main takeaway is that the number of words in a `b32` string value, to maintain portability with C strings, is greater than or equal to the number of words in a `b64` string. This difference in size is the **32-bit string word overhead**.

### Header

The `b32` header is:

| `word_size` | `color` | `tag`  |
| ----------- | ------- | ------ |
| 22 bits     | 2 bits  | 8 bits |

and the `b64` header is:

| `word_size` | `color` | `tag`  |
| ----------- | ------- | ------ |
| 54 bits     | 2 bits  | 8 bits |

With `bx32` the C ABI requires the use of 64-bit qwords (aka. 64-bit pointers) on a 64-bit CPU.
So the header is the lower 32-bits of the 64-bit qword header on little-endian machines:

|            | high dword (zeroed; unused) | `word_size` | `color` | `tag`  |
| ---------- | --------------------------- | ----------- | ------- | ------ |
| width:     | 32 bits                     | 22 bits     | 2 bits  | 8 bits |
| start bit: | 32                          | 10          | 2       | 0      |

and on rarer big-endian machines:

|            | `tag`  | `color` | `word_size` | high dword (zeroed; unused) |
| ---------- | ------ | ------- | ----------- | --------------------------- |
| width:     | 8 bits | 2 bits  | 22 bits     | 32 bits                     |
| start bit: | 0      | 2       | 10          | 32                          |

All that means is that a `uint64_t` right-shift in C of 10 bits (`>> 10`) will consistently get the `word_size`.

For all intents and purposes the header looks exactly like the Space-Time Profiler
set to 32-bits wide (confer [mlvalues.h](https://github.com/ocaml/ocaml/blob/8eb41f72ded84df884c3671734c947f612091f84/runtime/caml/mlvalues.h#L106-L112)):

```
For x86-64 with Spacetime profiling:
  P = PROFINFO_WIDTH (as set by "configure", currently 26 bits, giving a
    maximum block size of just under 4Gb)
     +----------------+----------------+-------------+
     | profiling info | wosize         | color | tag |
     +----------------+----------------+-------------+
bits  63        (64-P) (63-P)        10 9     8 7   0
```

<!-- 
| low dword (unused) | `word_size` | `color` | `tag`  |
| ------------------ | ----------- | ------- | ------ |
| 32 bits            | 22 bits     | 2 bits  | 8 bits |

and on rarer big-endian machines:

| `tag`  | `color` | `word_size` | high dword (unused) |
| ------ | ------- | ----------- | ------------------- |
| 8 bits | 2 bits  | 22 bits     | 32 bits             |

In other words, the least significant dword of the 64-bit qword is significant on little-endian machines,
and the most significant dword is significant on big-endian machines.
-->

## bx32 Marshalling

### Marshalling Goal - `b32` read compatibility

All values marshalled by a `b32` bytecode process should be readable in an bx32 ABI process.

### Marshalling Goal - `b32` write compatibility

> The following is a soft goal as it is not strictly necessary.

All values marshalled by an bx32 process should be readable in an `b32` bytecode process.

> The following is the strict goal.

All values marshalled by an bx32 process should be readable in a bx32 process.

### Marshalling Goal - Equivalent word offsets

The number of words written during marshalling by a `b32` bytecode process must be the same number of words occupied in memory by an bx32 process during unmarshalling. That simplifies the logic to adopt bx32, especially to accurately size the [heap chunks](#pages).

### Strings

To maintain [Equivalent Word Offsets](#marshalling-goal---equivalent-word-offsets), 
the [32-bit string word overhead](#in-memory-representation) is padded with zero-length arrays which each occupy 1 header word and 0 field words. So:

- 1 `string` value is unmarshalled which occupies the denser 64-bit word size.
- N zero-length `array` values are unmarshalled to pad the N words of 32-bit string word overhead.

During the first major garbage collection cycle after unmarshalling, the zero-length arrays will be garbage collected since there will be no references to those strings.

The patch has C comments with a proof that there is a non-negative overhead for strings in the bx32 ABI compared to the b64 ABI.
So a procedure to fill the overhead with 1-word, zero-length `array` values is well-defined.

### Custom Blocks

There is a non-negative overhead for bx32 custom blocks that is similar to the [32-bit string word overhead](#in-memory-representation).

The overhead, like for [strings](#strings), is filled with zero-length `array` values.

The patch has C comments with a proof that there is a non-negative overhead for custom blocks in the bx32 ABI compared to the b64 ABI.
So a procedure to fill the overhead with 1-word, zero-length `array` values just like was done for [strings](#strings) is well-defined.

### Floats

The `float` type is 1 header word plus 2 field words (2 * 32bit word = 64 bit double) which is the same number of words occupied by `b32`. However, `b64` only occupies 1 header word and 1 field word.

### Native Ints

The OCaml type `int` (aka. the C type `intnat`) is 64-bit, but is serialized and deserialized as 32-bit for compatibility with `b32`.

Integer overflow detection detects overflows for 32-bits just like `b32`.

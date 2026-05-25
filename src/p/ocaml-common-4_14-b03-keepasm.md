# Keep assembly language files

If no `./configure --disable-debug-runtime` was supplied, all
ocamlopt generated libraries and executables (OCaml runtime,
OCaml standard library, OCaml "other" libraries) will have
assembly language source code available.

That means C/assembly debuggers can step into the assembly
code of the Standard Library, which is very helpful when
debugging `external name : type = C-function-name` statements.

The added `ocamlopt` flags are:

- `-dstartup`: keep camlstartup*.asm/camlstartup*.S
  startup assembly source code available
- `-S`: keep camlasm*.asm/camlasm*.S intermediate assembly
  source code available

Q: Why the `debug-runtime` flag?

Answer: Didn't want to introduce a new compiler flag (less
patching!). `debug-runtime` has a very high overlap with when
you want to have assembly source code available.

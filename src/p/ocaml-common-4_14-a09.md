# a09

Commit: 4b519da2faabc9bddde6604233a94d0a81cda28f

Message:

```text
Compute the bytecode launcher stub in ocamlc

The various camlheader files are now folded into a single
runtime-launch-info file. On all systems, this file now contains the
executable stub launcher (from stdlib/header{,nt}.c) as well as the
following pieces of configuration information:
- Whether shebang scripts are supported
- How to find sh if the path to the interpreter is not valid for a
  shebang
- The location of the runtime executables (i.e. the bindir OCaml was
  configure'd with)

Since it no longer knows the name of the runtime (ocamlrun, ocamlrund,
etc.), the executable header no longer contains a default runtime path.
If the executable header is used, then the RNTM section must always be
written to the bytecode image. In passing, tools/ocamlsize is updated to
handle this and the display of default runtimes correctly.

In refactoring this code, several bugs are fixed. The validity checking
of shebangs is now correct in all cases. Previously, if OCaml was
configure'd with a prefix longer than 125 characters, the compiler's
tools were installed with correct shebang headers, but executables
produced by ocamlc after installation had invalid shebang headers. In
addition to spaces, newline and tab are now recognised as being invalid
characters for a shebang header. Finally, ocamlc no longer assumes that
sh resides at /bin/sh but by default uses the correct Posix mechanism of
querying `command -p -v sh` to determine the location.

Since 4.02.2, the compiler has generated a host and target set of header
files, permitting external cross-compilation solutions. The path to
ocamlrun on the target system can already be customised by specifying
--with-target-bindir=<path>. This support is extended further with
--with-target-sh which allows the location of sh on the target system
to be specified (for when that differs from the host system on which the
compiler is run). Furthermore, specifying --without-target-sh will cause
the executable header to be used instead.

Deviations from original:
  - Header name remains camlheader rather than runtime-launch-info
  - camlheaderd and camlheaderi are still installed, but they just
    contain /usr/bin/false as the "interpreter" (i.e. they're dummy
    files). camlheader_ur is likewise still installed, but unused.
  - Two minor typos in stdlib/Makefile and tools/ocamlsize corrected

(cherry picked from commit 8681e66c49315cd340ac3f39908160a3a9c51076)
(cherry picked from commit f08c2574a355dd637fa5f30c0b5ebd274933d296)

```

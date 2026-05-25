# a13

Commit: 81e859960c9b9a5b9facaa011520f08dc0494a31

Message:

```text
Explicitly compile the primitives object

In bytecode, when compiling a custom runtime (when using any of -custom,
-output-obj, -output-complete-obj or -output-complete-exe), the
camlprim.c file is passed directly to the linker. When this was
originally done, the cost was a single typedef for the value type, but
now this process involves considerable code duplication both for the
-fdebug-prefix-map implementation and for the full definition of the
value type.

The primitives file is now explicitly compiled, which means it gets
treated in the same way as a C file passed to ocamlc and in particular
can `#include <caml/mlvalues.h>` to remove the definitions otherwise
duplicated with <caml/config.h>. Using `Ccomp.compile_file` also allows
the duplicate machinery for `-fdebug-prefix-map` to be deleted from
Bytelink.

(cherry picked from commit 4741c63e60ba7f7ff911c0a5fc5e3ce88b521953)
(cherry picked from commit 305a7e98425de659d8cfd9cf93e9b3d65274f26d)

```

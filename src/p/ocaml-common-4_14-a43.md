# a43

Commit: 3c7bc7dcc56d318aa46966db467c73596de35de8

Message:

```text
Harden startup of -custom executables

By default, ocamlrun first tries to resolve argv[0] to determine where
the bytecode image is and then tries opening the executable image
itself. This is obviously correct for ocamlrun, when being called using
a shebang or executable header, but it's not correct for -custom
executables where we _know_ that the bytecode image should be with the
executable. To achieve this, a new mode is added to
caml_byte_program_mode (and the existing ones renamed) such that
caml_byte_program_mode is now STANDARD (for ocamlrun - the existing
behaviour), APPENDED (for -custom executables - the new behaviour) and
EMBEDDED (for -output-complete-exe/-output-obj - the original use of
it).

The mode is also set directly by the linker, rather than having a
default in libcamlrun which is then overridden by the startup code for
-output-complete-exe.

In the new APPENDED mode, if caml_executable_name is implemented (i.e.
it returns a string) then this file _must_ contain the bytecode image
and no other mechanisms are used. On platforms where
caml_executable_name is not implemented, APPENDED falls back to STANDARD
for compatibility.

Technically, this stops an argv[0] injection attack on setuid/setgid
-custom bytecode executables, although setuid should be used with
-output-complete-exe, if at all.

(cherry picked from commit b65dc45cc465ef452af464c9f6966410a86513b7)

```

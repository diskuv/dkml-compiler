# a12

Commit: cdb391d48bc88b2a47c29055d621be516bfe6da9

Message:

```text
Partially enable shebang headers on Cygwin

Historically, shebang headers were disabled on Cygwin partly because of
issues in Cygwin itself and partly because it allowed executables
produced by ocamlc to be started outside of a Cygwin shell (i.e. from
Windows itself, either at the Command Prompt or from Explorer).

The build has long since supported a separate set of headers to use when
building the compiler vs for use by ocamlc after installation, so the
compiler is now configured to default to shebang scripts for the tools
themselves (ocamlc.byte, etc.) while still retaining the previous
behaviour for executables produced by ocamlc. The user may override this
by configuring --with-target-sh=sh

(cherry picked from commit 6ddbd7e9f2dbd973e2117860093d78ac22d3fc65)
(cherry picked from commit 2ef756f3b6537307e5b6779d1ee28760845509c0)

```

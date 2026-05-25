# a72

Commit: 180299df600c859a4d570030f1ce9ed92c878c5a

Message:

```text
Don't explicitly install main.cmx and optmain.cmx

It's necessary to install main.o and optmain.o because the two modules
are not part of ocamlbytecomp.cmxa and ocamloptcomp.cmxa, but the .cmx
files are already installed as part of wildcard patterns on driver/

(cherry picked from commit 6864f1a686144e36075cc84140503e5d2d0e586a)

```

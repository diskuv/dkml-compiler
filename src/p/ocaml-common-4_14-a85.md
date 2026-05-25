# a85

Commit: 673a915d9ea6226539a1eb26fbc8a82e1a6ab2f5

Message:

```text
Generate an opam .install file and support script

make INSTALL_MODE=opam install generates $OPAM_PACKAGE_NAME.install and
$OPAM_PACKAGE_NAME-fixup.sh ($OPAM_PACKAGE_NAME defaults to
ocaml-compiler). Nothing is installed by this mode. The fixup.sh script
is intentionally not made executable (it should be invoked explicitly
with sh) and creates symbolic links, if required, and also manually
copies the files to the doc dir, as the .install file format doesn't
allow the correct location to be specified.

(cherry picked from commit 3c66f2ed307648bee04607bffdeaaa33568fa266)

```

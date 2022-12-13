# Developing

## Windows

If you have DKML already installed, you can do the following to build the
compiler into a local switch. Make sure you have done a `git commit` before
doing the commands below:

```powershell
with-dkml rm -rf _opam
opam switch create . --empty --repos default
opam pin add dkml-runtime-common "git+file://$(with-dkml cygpath -am ../drc/.git)" --yes
opam pin add ocaml -k version 4.14.0 --no-action
opam install . --yes
```

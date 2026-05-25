# a89

Commit: be55699c12277495310a976afc8d13f39d39583a

Message:

```text
Mark input dependencies as build

Mitigates an issue with opam install --assume-built since build
dependencies are ignored. The semantics should remain consistent: in
particular, as there is only a single version of each of these packages,
the key issue is that removing the package will still trigger the
correct behaviour as the dependency graph will change.

(cherry picked from commit e91a6e70eaf0cbd87e9cb21f6378e68983c9a60e)

```

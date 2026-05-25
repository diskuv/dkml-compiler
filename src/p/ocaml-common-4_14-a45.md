# a45

Commit: 95b856752f010a00a6125345dc78a73d3d958e2e

Message:

```text
Add %standard_library_default

%standard_library_default allows Config.standard_library_default to be
converted to a compile-time derived value, as with existing compile-time
constants such as %backend_type, etc. This paves the way for allowing
Config.standard_library_default to be changed at link-time, rather than
fixed when the Config module itself is compiled.

(cherry picked from commit e995af59895ebf6188fae12c13db9bf6191ef7ad)

```

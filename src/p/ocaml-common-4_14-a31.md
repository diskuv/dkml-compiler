# a31

Commit: b9641bfcc9bfd5a1e30c34b2b426397a6ab68451

Message:

```text
Don't add a double-separator when locating ld.conf

When calculating the full path for ld.conf, the runtime unconditionally
concatenated "/ld.conf". This is harmless when the separators appear in
the middle of a path ("/usr/local/lib/ocaml//ld.conf" is equivalent to
the version with only single slashes), but it is technically incorrect
for two corners cases with OCAMLLIB and CAMLLIB:

- if either is explicitly set to "/" then "//ld.conf" is _not_ the same
  file as "/ld.conf". This is mildly relevant on Windows and Cygwin
  where the two initial slashes (including as "\/" for native Windows)
  will be interpreted as a UNC path
- if either is explicitly blank, then "ld.conf" (i.e. ld.conf in the
  current directory) is a less illogical file to open than "/ld.conf"

(cherry picked from commit c7fde9c19b5f9752ba8b6bc53e8dd0de064cd724)

```

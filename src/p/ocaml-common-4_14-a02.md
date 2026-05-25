# a02

Commit: d2a892c8dccf3a2ccd843087ca1b042592c75d8d

Message:

```text
Generate an OCaml quoted string ID in configure

The string @QS@ is available to use in template.in files that produce
OCaml code allowing strings to be written as
{@QS@|@variable_from_configure@|@QS@} guaranteeing that any value of
@variable_from_configure@ yields a properly quoted OCaml string.

The calculation inserts 'o' characters until none of the strings passed
to AC_SUBST include the sequence |o..o}

(cherry picked from commit 0222801d9c57d5c4188ca1d2a13d2e734892a44a)
(cherry picked from commit 1293d8c6d8a2e62226c2d0637e839c4c0eeda32f)

```

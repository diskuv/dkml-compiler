# a76

Commit: d20d0273661fa211a1ffb7cd7fc3b2c28abec7e1

Message:

```text
Eliminate local for loops in install

Continue to use for when invoking recursive make calls, but use
$(foreach ..) to generate command sequences so that macros can be used
in them.

(cherry picked from commit 395b517f8f4b9f695459f9cd734c25c0173ef23e)

```

# a83

Commit: d2226089ec0241145039e3c3f179bc1ac73c80c9

Message:

```text
Use macros to generate installation commands

make install works as it did before. All the commands in the install
targets now go through a macro call which allows the semantic intent of
each command to be more clearly specified.

(cherry picked from commit 476688b137c8f42bb4cc7aa7a6128f5f3b43a146)

```

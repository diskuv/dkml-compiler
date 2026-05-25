# a75

Commit: b801f7eb0996ce45752a6aac703946d1ec48fd4b

Message:

```text
Use implicit names when installing ocamldoc

The ocamldoc binaries were installed using a relative path. They're the
only binaries installed that way - switch them to use an implicit path,
as it's easier to make an implicit path subsequently relative if needed
than vice versa.

(cherry picked from commit 9e0ae925378088118ef45504bccb13f24b390bd6)

```

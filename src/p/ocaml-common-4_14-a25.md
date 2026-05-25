# a25

Commit: 9945c95b20966948dbda8ad3a2916b2c6b408ce2

Message:

```text
Make caml/exec.h independent

Have exec.h include <stdint.h> itself. The bytecode executable header
now only depends on exec.h.

(cherry picked from commit f37343978547d0afe277107dd6d5876a60dad320)

```

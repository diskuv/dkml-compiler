# a59

Commit: 6aeaa97578865d275a375b93c50c46c78e623b10

Message:

```text
Remove metadata from runtime-launch-info

-launch-method encapsulates the first line of runtime-launch-info. The
argument to -launch-method is extended slightly to encompass the second
line, thus `-launch-method 'sh /usr/local/bin'` represents the default
runtime-launch-info file on Unix. Additional fields are added to Config
so that the installed compiler simply uses default values, rather than
reading the two lines from runtime-launch-info. The build of the
compiler itself explicitly uses `-launch-method`, which leaves only the
executable launcher compiled from stdlib/header.c in
runtime-launch-info.

(cherry picked from commit 3370649caa1637b343dd78bbf28eab477b5eb139)

```

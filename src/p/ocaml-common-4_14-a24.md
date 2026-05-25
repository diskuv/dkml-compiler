# a24

Commit: 7039b319980563b5534c53c528c92d5317f60389

Message:

```text
Reduce tmpheader.exe to 4-5KiB on Windows

stdlib/headernt.c was adapted in OCaml 3.00 to reduce its size by
avoiding the use of the CRT and using Windows API functions directly
(this is a well-studied trick on Windows, principally as a puzzle for
producing tiny binaries).

This got "regressed" slightly in OCaml 4.06, in the complex introduction
of wide character support for Windows, as the mingw-w64 incantation
required was unclear, so the entry point was changed to wmain, and the
size of the header increased.

By switching from wcslen (a CRT function) to lstrlen (a Win32 API
function), headernt.c again only requires kernel32.dll.

Additional flags are added for both ld (mingw-w64) and link (MSVC) to
squeeze every last byte out of tmpheader.exe. The MSVC version of the
header is once again no longer passed through strip, as this was found
to be corrupting the executable (and had never been reducing its size
anyway).

(cherry picked from commit 1401ab9b174f3fc3e5a819dd4054899ba2553a7a)

```

# ocamlopt dependency extension

The Windows 4.14.3 optimized stdlib build needed a fix because `stdlib/Makefile` depended on `../ocamlopt` even though the compiler artifact on Windows is `ocamlopt.exe`. The fix changes `OPTCOMPILER` to include `$(EXE)` so the native stdlib rules depend on the real Windows executable name.

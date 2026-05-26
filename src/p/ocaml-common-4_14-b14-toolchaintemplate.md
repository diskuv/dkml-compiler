# toolchain template

The relocatable 4.14.3 patch stack needed a fix because `configure` now generates `testsuite/tools/toolchain.ml` but the source tree did not ship the required `toolchain.ml.in` template. The fix adds `testsuite/tools/toolchain.ml.in` as a generated-template source file with the target bindir and launch/search metadata placeholders that the configure patches already substitute.

# a48

Commit: 38daa7ffaaeff68af7090af33c948400a9e2ed74

Message:

```text
Use %standard_library_default in Config

Config.standard_library_default is now implemented using the
%standard_library_default primitive. This allows a convenient test which
can be added for `-set-runtime-default`.

The change also makes the host-like nature of of
Config.standard_library_default clearer, as the build of the
cross-compiler must now (correctly) specify the location of its (target)
Standard Library.

(cherry picked from commit 9cbf2174ef542fb4ea89589a97949b8a9a2ef016)

```

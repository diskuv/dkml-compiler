# MSVC cflags

When we supply our own CFLAGS (ex. `/Od`) we don't want warnings like:

```text
cl : Command line warning D9025 : overriding '/O2' with '/Od'
cl : Command line warning D9025 : overriding '/MDd' with '/MD'
```

Setting `CFLAGS_MSVC=/MDd ...` avoids OCaml ./configure adding `/O2` and `/MD` and
instead sets whatever is in `CFLAGS_MSVC`.

## `-wd5287`

Newer MSVC (ex. VS 2022 17.14 / `cl` 14.44) emits warning C5287 ("operands are
different enum types") for frozen OCaml 4.14.3 runtime source such as
`bigarray.c`. Because OCaml's `$cc_warnings` enables `-WX` (warnings as errors),
that benign migration warning becomes a fatal `error C2220` and aborts
`make coldstart`. `-wd5287` is appended to `common_cflags` (both the default and
the `CFLAGS_MSVC` override branch) to demote only C5287 while keeping `-WX` for
every other warning. It is applied at the cflags level rather than as a source
patch because C5287 is not specific to `bigarray.c`.

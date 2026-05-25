# MSVC cflags

When we supply our own CFLAGS (ex. `/Od`) we don't want warnings like:

```text
cl : Command line warning D9025 : overriding '/O2' with '/Od'
cl : Command line warning D9025 : overriding '/MDd' with '/MD'
```

Setting `CFLAGS_MSVC=/MDd ...` avoids OCaml ./configure adding `/O2` and `/MD` and
instead sets whatever is in `CFLAGS_MSVC`.

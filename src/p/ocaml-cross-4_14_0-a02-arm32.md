# ARM32

Example target host ABIs are:

* `--host=armv7-none-linux-androideabi`

Changes:

1. Our PR: <https://github.com/ocaml/ocaml/pull/10860>
2. Fixed bug from an earlier PR https://github.com/ocaml/ocaml/pull/8936
   that flipped `lbl_got` and `lbl_pic`.
   New code is:

   ```diff
          (fun { lbl_got; lbl_pic } ->
   -        `{emit_label lbl_pic}:	.word	_GLOBAL_OFFSET_TABLE_-({emit_label lbl_got}+{emit_int offset})\n`)
   +        `{emit_label lbl_got}:	.word	_GLOBAL_OFFSET_TABLE_-({emit_label lbl_pic}+{emit_int offset})\n`)
          env.gotrel_literals;
   ```

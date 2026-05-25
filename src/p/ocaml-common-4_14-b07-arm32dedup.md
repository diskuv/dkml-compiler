# arm32 deduplicate labels

Problem that only appears on clang (not former GNU AS used before Android NDK 24):

```text
make: Entering directory '/workspaces/dkml-compiler/dist-android_arm32v7a-on-linux_x86/opt/mlcross/android_arm32v7a/src/ocaml/stdlib'
/usr/bin/env /workspaces/dkml-compiler/dist-android_arm32v7a-on-linux_x86/opt/mlcross/android_arm32v7a/src/ocaml/support/ocamloptTarget.wrapper -strict-sequence -absname -w +a-4-9-41-42-44-45-48-70 -g -warn-error +A -bin-annot -nostdlib -principal -safe-string -strict-formats -dstartup -S  -nopervasives -c camlinternalAtomic.ml
camlinternalAtomic.s:94:1: error: symbol '.L100' is already defined
.L100:
^
camlinternalAtomic.s:146:1: error: symbol '.L105' is already defined
.L105:
^
camlinternalAtomic.s:173:1: error: symbol '.L106' is already defined
.L106:
^
camlinternalAtomic.s:202:1: error: symbol '.L108' is already defined
.L108:
^
camlinternalAtomic.s:262:1: error: symbol '.L110' is already defined
.L110:
^
camlinternalAtomic.s:289:1: error: symbol '.L112' is already defined
.L112:
^
File "/workspaces/dkml-compiler/dist-android_arm32v7a-on-linux_x86/opt/mlcross/android_arm32v7a/src/ocaml/stdlib/camlinternalAtomic.ml", line 1:
Error: Assembler error, input left in file /workspaces/dkml-compiler/dist-android_arm32v7a-on-linux_x86/opt/mlcross/android_arm32v7a/src/ocaml/stdlib/camlinternalAtomic.s
make: *** [Makefile:231: camlinternalAtomic.cmx] Error 2
make: Leaving directory '/workspaces/dkml-compiler/dist-android_arm32v7a-on-linux_x86/opt/mlcross/android_arm32v7a/src/ocaml/stdlib'
```

Here is the definition of a function:

```armasm
# lines 1 - 82
camlCamlinternalAtomic__make_9: # line 83
	.file	2	"camlinternalAtomic.ml"
	.loc	2	27
	.cfi_startproc
	.loc	2	27
	sub	sp, sp, #0x8 #  Beginning of [Lprologue]
	.cfi_adjust_cfa_offset	8
	.cfi_offset 14, -4
	str	lr, [sp, #4]
.L100: # line 92        
	.loc	2	27   #  End of [Lprologue]
.L100: # line 94.       Beginning and end of [Llabel]
	.loc	2	27
   sub     alloc_ptr, alloc_ptr, #0x8
	ldr	r1, [domain_state_ptr, 0]
     cmp     alloc_ptr, r1
     bcc     .L102
.L103:     add     r1, alloc_ptr, #4
	ldr	lr, [sp, #4]
	movs	r2, #0x400
	str	r2, [r1, #-4]
	str	r0, [r1, #0]
	mov	r0, r1
	add	sp, sp, #0x8
	.cfi_adjust_cfa_offset	-8
	bx	lr
	.cfi_adjust_cfa_offset	8
.L102:	bl	caml_call_gc(PLT)
.L101:	b	.L103
	.cfi_endproc
	.type	camlCamlinternalAtomic__make_9, %function
	.size	camlCamlinternalAtomic__make_9, .-camlCamlinternalAtomic__make_9
```

This patch gets rid of any duplicate, consecutive labels.

 ; Copyright (c) 2008 - 2021 Advanced Micro Devices, Inc.

 ;Permission is hereby granted, free of charge, to any person obtaining a copy
 ;of this software and associated documentation files (the "Software"), to deal
 ;in the Software without restriction, including without limitation the rights
 ;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 ;copies of the Software, and to permit persons to whom the Software is
 ;furnished to do so, subject to the following conditions:

 ;The above copyright notice and this permission notice shall be included in
 ;all copies or substantial portions of the Software.

 ;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 ;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 ;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 ;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 ;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 ;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 ;THE SOFTWARE.

;+ Authoritative Source: dksdk-cmake/cmake/targets/310-ocaml-runtimelib/msvc/setjmp.asm
;+ Adapted from https://github.com/ROCm-Developer-Tools/clr/blob/5914ac3c6e9b3848023a7fa25e19e560b1c38541/rocclr/os/setjmp.asm
;+
;+ Extensive changes by @jonahbeckford. Permission given by @jonahbeckford to use the
;+ same license as github.com/ocaml/ocaml:
;+
;+ 1. No [_StackContext_longjmp] procedure and no [_Os_setCurrentStackPtr] procedure
;+ 2. No [_StackContext] prefix
;+ 3. Re-ordered the registers to conform to Microsoft's [struct __JUMP_BUFFER]
;+    Confer:
;+      C:\Program Files*\Microsoft Visual Studio\*\*\VC\Tools\MSVC\*\include\setjmp.h

ifndef _WIN64
    .386
    .model flat, c
endif ; !_WIN64

OPTION PROLOGUE:NONE
OPTION EPILOGUE:NONE
.code

ifndef _WIN64

_setjmp proc
    mov ecx,0[esp]          ;+ IP after jump is the return address of setjmp()
    mov edx,4[esp]          ;+ EDX is &(struct _JUMP_BUFFER)

    mov 0[edx],ebp

    mov 4[edx],ebx

    mov 8[edx],edi

    mov 0Ch[edx],esi

    lea eax,4[esp]
    mov 10h[edx],eax

    mov 14h[edx],ecx

    xor eax,eax             ;+ return 0
    ret
_setjmp endp

else ; _WIN64

_setjmp proc
    mov r8, 0[rsp]          ;+ IP after jump is the return address of setjmp()

    ;+ RCX (first parameter in x64 calling convention) is &(struct _JUMP_BUFFER)

    ;+ @jonahbeckford:
    ;+ - getting information on _JUMP_BUFFER.Frame is difficult
    ;+ - Windows Server 2003 uses it to distinguish safe/unsafe jump:
    ;+   https://github.com/selfrender/Windows-Server-2003/blob/5c6fe3db626b63a384230a1aa6b92ac416b0765f/base/crts/crtw32/misc/amd64/longjmp.asm#L89-L90
    ;+ - that corresponds to <setjmp.h> bypassing termination handling
    ;+   while <setjmpex.h> does not bypass:
    ;+   https://learn.microsoft.com/en-us/cpp/cpp/timing-of-exception-handling-a-summary?view=msvc-170
    ;+ - don't trust stackoverflow, but the experiment has concurring results:
    ;+   https://stackoverflow.com/a/39098501
    ;+ ==> set the Frame to 0. Termination handling will be set in [.Frame]
    ;+     if and when the programmer users <setjmpex.h>
    mov qword ptr 0[rcx], 0 ;+ _JUMP_BUFFER.Frame (unsigned __int64)

    mov 8[rcx],rbx

    lea r9,8[rsp]
    mov 10h[rcx],r9         ;+ _JUMP_BUFFER.Rsp

    mov 18h[rcx],rbp
    mov 20h[rcx],rsi
    mov 28h[rcx],rdi
    mov 30h[rcx],r12
    mov 38h[rcx],r13
    mov 40h[rcx],r14
    mov 48h[rcx],r15
    mov 50h[rcx],r8         ;+ _JUMP_BUFFER.Rip

    stmxcsr 58h[rcx]        ;+ _JUMP_BUFFER.MxCsr
    fnstcw 5ch[rcx]         ;+ _JUMP_BUFFER.FpCsr
    ;+ 5eh[rcx]             ;+ _JUMP_BUFFER.Spare

    movdqa 60h[rcx],xmm6
    movdqa 70h[rcx],xmm7
    movdqa 80h[rcx],xmm8
    movdqa 90h[rcx],xmm9
    movdqa 0A0h[rcx],xmm10
    movdqa 0B0h[rcx],xmm11
    movdqa 0C0h[rcx],xmm12
    movdqa 0D0h[rcx],xmm13
    movdqa 0E0h[rcx],xmm14
    movdqa 0F0h[rcx],xmm15
    xor rax,rax             ;+ return 0
    ret
_setjmp endp

endif ; _WIN64

end

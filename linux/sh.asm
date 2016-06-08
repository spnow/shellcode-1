

; x86/x64 execve for linux
; odzhan

    bits 32
    
    xor    eax, eax
    inc    eax
    jz     x64
    
%include "sh32.asm"
    
x64:

%include "sh64.asm"
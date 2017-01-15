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

    bits 32
    
    %ifndef BIN
      global _getapix
    %endif
    
struc pushad_t
  _edi resd 1
  _esi resd 1
  _ebp resd 1
  _esp resd 1
  _ebx resd 1
  _edx resd 1
  _ecx resd 1
  _eax resd 1
  .size:
endstruc

; in: eax = s
; out: crc-32c(s)
;
crc32c:    
    pushad
    xchg   eax, esi          ; esi = s
    xor    eax, eax          ; eax = 0
    cdq                      ; edx = 0
crc_l0:
    lodsb                    ; al = *s++ | 0x20
    or     al, 0x20
    xor    dl, al            ; crc ^= c
    push   8
    pop    ecx    
crc_l1:
    shr    edx, 1            ; crc >>= 1
    jnc    crc_l2
    xor    edx, 0x82F63B78
crc_l2:
    loop   crc_l1
    cmp    al, 0x20
    jne    crc_l0 
    mov    [esp+_eax], edx
    popad
    ret
    
; in: ebx = base of module to search
; out: eax = api address resolved in IAT
;    
search_impx:    
    xor    eax, eax    ; api_adr = NULL
    pushad
    ; eax = IMAGE_DOS_HEADER.e_lfanew
    mov    eax, [ebx+3ch]    
    add    eax, 8     ; add 8 for import directory
    
    ; eax = IMAGE_DATA_DIRECTORY.VirtualAddress
    mov    eax, [ebx+eax+78h]
    test   eax, eax
    jz     imp_l2
    
    lea    ebp, [eax+ebx]
imp_l0:
    mov    esi, ebp      ; esi = current descriptor
    lodsd                ; OriginalFirstThunk +00h
    xchg   eax, edx      ; temporarily store in edx
    lodsd                ; TimeDateStamp      +04h
    lodsd                ; ForwarderChain     +08h
    lodsd                ; Name_              +0Ch
    test   eax, eax
    jz     imp_l2        ; if (Name_ == 0) goto imp_l2;
    
    add    eax, ebx
    call   crc32c
    mov    [esp+_edx], eax
    
    lodsd                 ; FirstThunk 
    mov    ebp, esi       ; ebp = next descriptor
    
    lea    esi, [edx+ebx] ; esi = OriginalFirstThunk + base
    lea    edi, [eax+ebx] ; edi = FirstThunk + base
imp_l1:
    lodsd                 ; eax = oft->u1.Function, oft++;
    scasd                 ; ft++;
    test   eax, eax       ; if (oft->u1.Function == 0)
    jz     imp_l0         ; goto imp_l0
    
    cdq                          
    inc    edx         ; will be zero if eax >= 0x80000000
    jz     imp_l1      ; oft->u1.Ordinal & IMAGE_ORDINAL_FLAG
    
    lea    eax, [eax+ebx+2] ; oft->Name_
    call   crc32c           ; get crc of API string  
    
    add    eax, [esp+_edx] ; eax = api_h + dll_h
    cmp    [esp+_ecx], eax ; found match?
    jne    imp_l1
    
    mov    eax, [edi-4]    ; ft->u1.Function    
imp_l2:
    mov    [esp+_eax], eax
    popad
    ret
    
; in:  ebx = base of module to search
; out: eax = api address resolved in EAT
;      
search_expx:
    pushad
    ; eax = IMAGE_DOS_HEADER.e_lfanew
    mov    eax, [ebx+3ch]            

    ; first directory is export
    ; ecx = IMAGE_DATA_DIRECTORY.VirtualAddress
    mov    ecx, [ebx+eax+78h] 
    jecxz  exp_l2

    ; eax = crc32c(IMAGE_EXPORT_DIRECTORY.Name)
    mov    eax, [ebx+ecx+0ch]
    add    eax, ebx
    call   crc32c  
    mov    [esp+_edx], eax
    
    ; esi = IMAGE_EXPORT_DIRECTORY.NumberOfNames
    lea    esi, [ebx+ecx+18h]
    push   4
    pop    ecx         ; load 4 RVA
exp_l0:
    lodsd              ; load RVA
    add    eax, ebx    ; eax = RVA2VA(ebx, eax)
    push   eax         ; save VA
    loop   exp_l0
    
    pop    edi          ; edi = AddressOfNameOrdinals
    pop    edx          ; edx = AddressOfNames
    pop    esi          ; esi = AddressOfFunctions
    pop    ecx          ; ecx = NumberOfNames 
    
    sub    ecx, ebx     ; ecx = VA2RVA(NumberOfNames, base)
    jz     exp_l2       ; exit if no api
exp_l3:
    mov    eax, [edx+4*ecx-4] ; get VA of API string
    add    eax, ebx           ; eax = RVA2VA(eax, ebx)
    call   crc32c             ; generate crc32 of api string 
    add    eax, [esp+_edx]    ; add crc32 of DLL string
    
    cmp    eax, [esp+_ecx]    ; found match?
    loopne exp_l3             ; --ecx && eax != hash
    jne    exp_l2             ; exit if not found
    
    xchg   eax, ebx
    xchg   eax, ecx
    
    movzx  eax, word [edi+2*eax] ; eax = AddressOfOrdinals[eax]
    add    ecx, [esi+4*eax] ; ecx = base + AddressOfFunctions[eax]
exp_l2:
    mov    [esp+_eax], ecx
    popad
    ret    
    
getapix:
_getapix:
    pushad
    mov    ebp, [esp+32+4]
    push   30h
    pop    ecx

    mov    eax, [fs:ecx] ; eax = (PPEB) __readfsdword(0x30);
    mov    eax, [eax+12] ; eax = (PMY_PEB_LDR_DATA)peb->Ldr
    mov    edi, [eax+12] ; edi = ldr->InLoadOrderModuleList.Flink
    jmp    gapi_l1
gapi_l0:
    mov    eax, ebp      ; eax = hash     
    call   search_expx
    test   eax, eax
    jnz    gapi_l2

    mov    edi, [edi]    ; edi = dte->InMemoryOrderLinks.Flink
gapi_l1:
    mov    ebx, [edi+24] ; ebx = dte->DllBase
    test   ebx, ebx
    jnz    gapi_l0
gapi_l2:
    mov    [esp+_eax], eax
    popad
    ret   
    
    
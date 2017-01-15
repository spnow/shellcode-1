
#include <windows.h>
#include <stdint.h>
#include <stdio.h>

#define RVA2VA(type, base, rva) (type)((ULONG_PTR) base + rva)

typedef void *PPS_POST_PROCESS_INIT_ROUTINE;

typedef struct _LSA_UNICODE_STRING {
  USHORT Length;
  USHORT MaximumLength;
  PWSTR  Buffer;
} LSA_UNICODE_STRING, *PLSA_UNICODE_STRING, UNICODE_STRING, *PUNICODE_STRING;

typedef struct _PEB_LDR_DATA {
  BYTE       Reserved1[8];
  PVOID      Reserved2[3];
  LIST_ENTRY InMemoryOrderModuleList;
} PEB_LDR_DATA, *PPEB_LDR_DATA;

typedef struct _RTL_USER_PROCESS_PARAMETERS {
  BYTE           Reserved1[16];
  PVOID          Reserved2[10];
  UNICODE_STRING ImagePathName;
  UNICODE_STRING CommandLine;
} RTL_USER_PROCESS_PARAMETERS, *PRTL_USER_PROCESS_PARAMETERS;

typedef struct _PEB {
  BYTE                          Reserved1[2];
  BYTE                          BeingDebugged;
  BYTE                          Reserved2[1];
  PVOID                         Reserved3[2];
  PPEB_LDR_DATA                 Ldr;
  PRTL_USER_PROCESS_PARAMETERS  ProcessParameters;
  BYTE                          Reserved4[104];
  PVOID                         Reserved5[52];
  PPS_POST_PROCESS_INIT_ROUTINE PostProcessInitRoutine;
  BYTE                          Reserved6[128];
  PVOID                         Reserved7[1];
  ULONG                         SessionId;
} PEB, *PPEB;

typedef struct _MY_PEB_LDR_DATA {
  ULONG      Length;
  BOOL       Initialized;
  PVOID      SsHandle;
  LIST_ENTRY InLoadOrderModuleList;
  LIST_ENTRY InMemoryOrderModuleList;
  LIST_ENTRY InInitializationOrderModuleList;
} MY_PEB_LDR_DATA, *PMY_PEB_LDR_DATA;

typedef struct _MY_LDR_DATA_TABLE_ENTRY
{
  LIST_ENTRY     InLoadOrderLinks;
  LIST_ENTRY     InMemoryOrderLinks;
  LIST_ENTRY     InInitializationOrderLinks;
  PVOID          DllBase;
  PVOID          EntryPoint;
  ULONG          SizeOfImage;
  UNICODE_STRING FullDllName;
  UNICODE_STRING BaseDllName;
} MY_LDR_DATA_TABLE_ENTRY, *PMY_LDR_DATA_TABLE_ENTRY;

// converts string to lowercase
uint32_t crc32c(const char *s)
{
  int i;
  uint32_t crc=0;
  
  do {
    crc ^= (uint8_t)(*s++ | 0x20);
    
    for (i=0; i<8; i++) {
      crc = (crc >> 1) ^ (0x82F63B78 * (crc & 1));
    }
  } while (*(s - 1) != 0);
  return crc;
}

LPVOID search_exp(LPVOID base, DWORD hash)
{
  PIMAGE_DOS_HEADER       dos;
  PIMAGE_NT_HEADERS       nt;
  DWORD                   cnt, rva, dll_h;
  PIMAGE_DATA_DIRECTORY   dir;
  PIMAGE_EXPORT_DIRECTORY exp;
  PDWORD                  adr;
  PDWORD                  sym;
  PWORD                   ord;
  PCHAR                   api, dll;
  LPVOID                  api_adr=NULL;
  
  dos = (PIMAGE_DOS_HEADER)base;
  nt  = RVA2VA(PIMAGE_NT_HEADERS, base, dos->e_lfanew);
  dir = (PIMAGE_DATA_DIRECTORY)nt->OptionalHeader.DataDirectory;
  rva = dir[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;
  
  // if no export table, return NULL
  if (rva==0) return NULL;
  
  exp = (PIMAGE_EXPORT_DIRECTORY) RVA2VA(ULONG_PTR, base, rva);
  cnt = exp->NumberOfNames;
  
  // if no api, return NULL
  if (cnt==0) return NULL;
  
  adr = RVA2VA(PDWORD,base, exp->AddressOfFunctions);
  sym = RVA2VA(PDWORD,base, exp->AddressOfNames);
  ord = RVA2VA(PWORD, base, exp->AddressOfNameOrdinals);
  dll = RVA2VA(PCHAR, base, exp->Name);
  
  // calculate hash of DLL string
  dll_h = crc32c(dll);
  
  do {
    // calculate hash of api string
    api = RVA2VA(PCHAR, base, sym[cnt-1]);
    // add to DLL hash and compare
    if (crc32c(api) + dll_h == hash) {
      // return address of function
      api_adr = RVA2VA(LPVOID, base, adr[ord[cnt-1]]);
      return api_adr;
    }
  } while (--cnt && api_adr==0);
  return api_adr;
}

LPVOID search_impx(LPVOID base, DWORD hash);
LPVOID search_expx(LPVOID base, DWORD hash);
 
LPVOID search_imp(LPVOID base, DWORD hash)
{
  DWORD                    api_h, dll_h, i, rva;
  PIMAGE_IMPORT_DESCRIPTOR imp;
  PIMAGE_THUNK_DATA        oft, ft;
  PIMAGE_IMPORT_BY_NAME    ibn;
  PIMAGE_DOS_HEADER        dos;
  PIMAGE_NT_HEADERS        nt;
  PIMAGE_DATA_DIRECTORY    dir;
  PCHAR                    dll;
  LPVOID                   api_adr=NULL;
  
  dos = (PIMAGE_DOS_HEADER)base;
  nt  = RVA2VA(PIMAGE_NT_HEADERS, base, dos->e_lfanew);
  dir = (PIMAGE_DATA_DIRECTORY)nt->OptionalHeader.DataDirectory;
  rva = dir[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress;
  
  // if no import table, return
  if (rva==0) return NULL;

  imp  = (PIMAGE_IMPORT_DESCRIPTOR) RVA2VA(ULONG_PTR, base, rva);
  
  for (i=0; api_adr==NULL; i++) 
  {
    if (imp[i].Name == 0) return NULL;
    
    dll   = RVA2VA(PCHAR, base, imp[i].Name);
    dll_h = crc32c(dll); 
    
    rva   = imp[i].OriginalFirstThunk;
    oft   = (PIMAGE_THUNK_DATA)RVA2VA(ULONG_PTR, base, rva);
    
    rva   = imp[i].FirstThunk;
    ft    = (PIMAGE_THUNK_DATA)RVA2VA(ULONG_PTR, base, rva);
        
    for (;; oft++, ft++) 
    {
      if (oft->u1.Ordinal == 0) break;
      // skip import by ordinal
      if (IMAGE_SNAP_BY_ORDINAL(oft->u1.Ordinal)) continue;
      
      rva = oft->u1.AddressOfData;
      ibn = (PIMAGE_IMPORT_BY_NAME)RVA2VA(ULONG_PTR, base, rva);
      
      if ((crc32c(ibn->Name) + dll_h) == hash) {
        api_adr = (LPVOID)ft->u1.Function;
        break;
      }
    }
  }
  return api_adr;
}
 
/**F*********************************************
 *
 * Obtain address of API from PEB based on hash
 *
 ************************************************/
LPVOID getapi (DWORD dwHash)
{
  PPEB                     peb;
  PMY_PEB_LDR_DATA         ldr;
  PMY_LDR_DATA_TABLE_ENTRY dte;
  LPVOID                   api_adr=NULL;
  
#if defined(_WIN64)
  peb = (PPEB) __readgsqword(0x60);
#else
  peb = (PPEB) __readfsdword(0x30);
#endif

  ldr = (PMY_PEB_LDR_DATA)peb->Ldr;
  
  // for each DLL loaded
  for (dte=(PMY_LDR_DATA_TABLE_ENTRY)ldr->InLoadOrderModuleList.Flink;
       dte->DllBase != NULL && api_adr == NULL; 
       dte=(PMY_LDR_DATA_TABLE_ENTRY)dte->InLoadOrderLinks.Flink)
  {
    api_adr=search_exp(dte->DllBase, dwHash);
  }
  return api_adr;
}

#ifdef TEST
int main(int argc, char *argv[])
{
  DWORD h=0;
  
  if (argc!=3) {
    printf("\nusage: getapi <DLL> <API>\n");
    return 0;
  }
  h = crc32c(argv[1]) + crc32c(argv[2]);
  printf("\nAddress of %s = %p", argv[2], getapi(h));
}
#endif


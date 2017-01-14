
#include <windows.h>
#include <stdint.h>

#define RVA2OFS(type, base, rva) (type)((ULONG_PTR) base + rva)

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

uint32_t crc32c(const char *s)
{
  int i;
  uint32_t crc=0;
  
  do {
    crc ^= (uint8_t)*s++;
    
    for (i=0; i<8; i++) {
      crc = (crc >> 1) ^ (0x82F63B78 * (crc & 1));
    }
  } while (*(s - 1) != 0);
  return crc;
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
  PIMAGE_DOS_HEADER        dos;
  PIMAGE_NT_HEADERS        nt;
  PVOID                    base;
  DWORD                    cnt=0, ofs=0, i, j;
  DWORD                    idx, rva, api_h, dll_h;
  PIMAGE_DATA_DIRECTORY    dir;
  PIMAGE_EXPORT_DIRECTORY  exp;
  PDWORD                   adr;
  PDWORD                   sym;
  PWORD                    ord;
  PCHAR                    api, dll, p;
  LPVOID                   api_adr=0;
  CHAR                     dll_name[64], api_name[128];
  
#if defined(_WIN64)
  peb = (PPEB) __readgsqword(0x60);
#else
  peb = (PPEB) __readfsdword(0x30);
#endif

  ldr = (PMY_PEB_LDR_DATA)peb->Ldr;
  
  // for each DLL loaded
  for (dte=(PMY_LDR_DATA_TABLE_ENTRY)ldr->InLoadOrderModuleList.Flink;
       dte->DllBase != NULL; 
       dte=(PMY_LDR_DATA_TABLE_ENTRY)dte->InLoadOrderLinks.Flink)
  {
    base = dte->DllBase;
    dos  = (PIMAGE_DOS_HEADER)base;
    nt   = RVA2OFS(PIMAGE_NT_HEADERS, base, dos->e_lfanew);
    dir  = (PIMAGE_DATA_DIRECTORY)nt->OptionalHeader.DataDirectory;
    rva  = dir[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;
    
    // if no export table, continue
    if (rva==0) continue;
    
    exp = (PIMAGE_EXPORT_DIRECTORY) RVA2OFS(ULONG_PTR, base, rva);
    cnt = exp->NumberOfNames;
    
    // if no api, continue
    if (cnt==0) continue;
    
    adr = RVA2OFS(PDWORD,base, exp->AddressOfFunctions);
    sym = RVA2OFS(PDWORD,base, exp->AddressOfNames);
    ord = RVA2OFS(PWORD, base, exp->AddressOfNameOrdinals);
    dll = RVA2OFS(PCHAR, base, exp->Name);
    
    // calculate hash of DLL string
    dll_h = crc32c(dll);
    
    do {
      // calculate hash of api string
      api = RVA2OFS(PCHAR, base, sym[cnt-1]);
      // add to DLL hash and compare
      if (crc32c(api)+dll_h == dwHash) {
        // return address of function
        api_adr=RVA2OFS(LPVOID, base, adr[ord[cnt-1]]);
        return api_adr;
      }
    } while (--cnt && api_adr==0);
  }
  return api_adr;
}

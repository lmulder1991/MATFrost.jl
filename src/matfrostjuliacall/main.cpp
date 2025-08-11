
#include <cstdint>
#include <windows.h>
#include <tchar.h>
#include <cstdio>
#include <strsafe.h>


#include <string>
#include <iostream>
#include <memory>

#include "matfrostjuliaserver.cpp"

// #define BUFSIZE 4096
//
// HANDLE g_hChildStd_IN_Rd = nullptr;
// HANDLE g_hChildStd_IN_Wr = nullptr;
// HANDLE g_hChildStd_OUT_Rd = nullptr;
// HANDLE g_hChildStd_OUT_Wr = nullptr;
//
// HANDLE g_hInputFile = NULL;
//
// void CreateChildProcess(void);
// void WriteToPipe(void);
// void ReadFromPipe(void);
// void ErrorExit(PCTSTR);
// TCHAR szName[]=TEXT("TestMap2");
//
// #define BUF_SIZE 1024


int main() {
   std:: cout << "Spawning";
   JuliaProcess jp = JuliaProcess::spawn(R"(C:\Users\jbelier\.julia\juliaup\julia-1.12.0-rc1+0.x64.w64.mingw32\bin\julia.exe)",
      R"(C:\Users\jbelier\Documents\JuliaEnvs\MATFrostDev)");


   std:: cout << "Before alloc";
   std::shared_ptr<std::array<int64_t, 500000000>> buf = std::make_shared<std::array<int64_t, 500000000>>();

   std:: cout << "Before alloc";

   std::array<int64_t, 500000000>& bufp = *buf;
   for (size_t i = 0; i < 500000000; i++) {
      bufp[i] = i;
   }


   std:: cout << "Writing" << std::endl;
   jp.write((uint8_t*) &bufp[0], 4000000000);
   jp.flush();



   std:: cout << "Finished writing" << std::endl;

   int64_t result = 0;
   jp.read((uint8_t*) &result, 8);

   // int64_t* el = (int64_t*) &buf[0];
   //
   // std::cout << el[432] << std::endl;
   // std::cout << el[5000] << std::endl;
   //
   // int64_t sum = 0;
   //
   // for (size_t i = 0; i < 5000; i++) {
   //    sum+= el[i];
   // }
   std::cout << "Final result: " << result << std::endl;

}
//
// int main2() {
//    std::cout << "Hello, World!" << std::endl;
//    SECURITY_ATTRIBUTES saAttr;
//
//    printf("\n->Start of parent execution.\n");
//
// // Set the bInheritHandle flag so pipe handles are inherited.
//
//    saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
//    saAttr.bInheritHandle = TRUE;
//    saAttr.lpSecurityDescriptor = NULL;
//
// // Create a pipe for the child process's STDOUT.
//
//    if ( ! CreatePipe(&g_hChildStd_OUT_Rd, &g_hChildStd_OUT_Wr, &saAttr, 0) )
//       ErrorExit(TEXT("StdoutRd CreatePipe"));
//
// // Ensure the read handle to the pipe for STDOUT is not inherited.
//
//    if ( ! SetHandleInformation(g_hChildStd_OUT_Rd, HANDLE_FLAG_INHERIT, 0) )
//       ErrorExit(TEXT("Stdout SetHandleInformation"));
//
// // Create a pipe for the child process's STDIN.
//
//    if (! CreatePipe(&g_hChildStd_IN_Rd, &g_hChildStd_IN_Wr, &saAttr, 0))
//       ErrorExit(TEXT("Stdin CreatePipe"));
//
// // Ensure the write handle to the pipe for STDIN is not inherited.
//
//    if ( ! SetHandleInformation(g_hChildStd_IN_Wr, HANDLE_FLAG_INHERIT, 0) )
//       ErrorExit(TEXT("Stdin SetHandleInformation"));
//
// // Create the child process.
//    std::cout << "Starting process" << std::endl;
//
//    TCHAR szCmdline[]=TEXT("C:\\Users\\jbelier\\.julia\\juliaup\\julia-1.12.0-rc1+0.x64.w64.mingw32\\bin\\julia.exe -e \"println(read(stdin, Int64))\"");
//    PROCESS_INFORMATION piProcInfo;
//    STARTUPINFO siStartInfo;
//    BOOL bSuccess = FALSE;
//
//    // Set up members of the PROCESS_INFORMATION structure.
//
//    ZeroMemory( &piProcInfo, sizeof(PROCESS_INFORMATION) );
//
//    // Set up members of the STARTUPINFO structure.
//    // This structure specifies the STDIN and STDOUT handles for redirection.
//
//    ZeroMemory( &siStartInfo, sizeof(STARTUPINFO) );
//    siStartInfo.cb = sizeof(STARTUPINFO);
//    siStartInfo.hStdError = g_hChildStd_OUT_Wr;
//    siStartInfo.hStdOutput = g_hChildStd_OUT_Wr;
//    siStartInfo.hStdInput = g_hChildStd_IN_Rd;
//    siStartInfo.dwFlags |= STARTF_USESTDHANDLES;
//
//    // Create the child process.
//
//    CreateProcessA(
//      R"(C:\Users\jbelier\.julia\juliaup\julia-1.12.0-rc1+0.x64.w64.mingw32\bin\julia.exe)",
//      szCmdline,     // command line
//      NULL,          // process security attributes
//      NULL,          // primary thread security attributes
//      TRUE,          // handles are inherited
//      0,             // creation flags
//      NULL,          // use parent's environment
//      NULL,          // use parent's current directory
//      &siStartInfo,  // STARTUPINFO pointer
//      &piProcInfo);  // receives PROCESS_INFORMATION
//
//    DWORD dwRead, dwWritten;
//    CHAR chBuf[BUFSIZE];
//    int64_t* intp = (int64_t*) chBuf;
//    HANDLE hParentStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
//
//    std::cout << "Reading file" << std::endl;
//
//    intp[0] = 73323;
//
//    WriteFile(g_hChildStd_IN_Wr, chBuf,
//       8, &dwWritten, NULL);
//
//    bSuccess = ReadFile( g_hChildStd_OUT_Rd, chBuf, BUFSIZE, &dwRead, NULL);
//    chBuf[5] = 0;
//    std::cout << dwRead << std::endl;
//    std::cout << chBuf[0] << chBuf[1] << chBuf[2] << chBuf[3] << chBuf[4] << std::endl;
//
//
//    // for (;;)
//    // {
//    //    bSuccess = ReadFile( g_hChildStd_OUT_Rd, chBuf, BUFSIZE, &dwRead, NULL);
//    //
//    //    // if( ! bSuccess || dwRead == 0 ) break;
//    //    //
//    //    // bSuccess = WriteFile(hParentStdOut, chBuf,
//    //    //                      dwRead, &dwWritten, NULL);
//    //    // if (! bSuccess ) break;
//    // }
// // Get a handle to an input file for the parent.
// // This example assumes a plain text file and uses string output to verify data flow.
//
//    // if (argc == 1)
//    //    ErrorExit(TEXT("Please specify an input file.\n"));
//    //
//    // g_hInputFile = CreateFile(
//    //     argv[1],
//    //     GENERIC_READ,
//    //     0,
//    //     NULL,
//    //     OPEN_EXISTING,
//    //     FILE_ATTRIBUTE_READONLY,
//    //     NULL);
//    //
//    // if ( g_hInputFile == INVALID_HANDLE_VALUE )
//    //    ErrorExit(TEXT("CreateFile"));
//
// // Write to the pipe that is the standard input for a child process.
// // Data is written to the pipe's buffers, so it is not necessary to wait
// // until the child process is running before writing data.
//
// //    WriteToPipe();
// //    printf( "\n->Contents of %S written to child STDIN pipe.\n", argv[1]);
// //
// // // Read from pipe that is the standard output for child process.
// //
//     // printf( "\n->Contents of child process STDOUT:\n\n");
//     // ReadFromPipe();
// //
// //    printf("\n->End of parent execution.\n");
//
// // The remaining open handles are cleaned up when this process terminates.
// // To avoid resource leaks in a larger application, close handles explicitly.
//
//    return 0;
// }
//
// void CreateChildProcess()
// // Create a child process that uses the previously created pipes for STDIN and STDOUT.
// {
//
//
//    // // If an error occurs, exit the application.
//    // if ( ! bSuccess )
//    //    ErrorExit(TEXT("CreateProcess"));
//    // else
//    // {
//    //    // Close handles to the child process and its primary thread.
//    //    // Some applications might keep these handles to monitor the status
//    //    // of the child process, for example.
//    //
//    //    CloseHandle(piProcInfo.hProcess);
//    //    CloseHandle(piProcInfo.hThread);
//    //
//    //    // Close handles to the stdin and stdout pipes no longer needed by the child process.
//    //    // If they are not explicitly closed, there is no way to recognize that the child process has ended.
//    //
//    //    CloseHandle(g_hChildStd_OUT_Wr);
//    //    CloseHandle(g_hChildStd_IN_Rd);
//    // }
// }
//
// void WriteToPipe(void)
//
// // Read from a file and write its contents to the pipe for the child's STDIN.
// // Stop when there is no more data.
// {
//    DWORD dwRead, dwWritten;
//    CHAR chBuf[BUFSIZE];
//    BOOL bSuccess = FALSE;
//
//    for (;;)
//    {
//       bSuccess = ReadFile(g_hInputFile, chBuf, BUFSIZE, &dwRead, NULL);
//       if ( ! bSuccess || dwRead == 0 ) break;
//
//       bSuccess = WriteFile(g_hChildStd_IN_Wr, chBuf, dwRead, &dwWritten, NULL);
//       if ( ! bSuccess ) break;
//    }
//
// // Close the pipe handle so the child process stops reading.
//
//    if ( ! CloseHandle(g_hChildStd_IN_Wr) )
//       ErrorExit(TEXT("StdInWr CloseHandle"));
// }

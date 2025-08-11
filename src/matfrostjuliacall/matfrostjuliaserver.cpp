/**
 * This file is responsible of managing the Julia process and offer a communication interface over pipes with the Julia
 * process. This class is free of MATLAB dependencies
 */
#include <cstdint>
#include <windows.h>
#include <tchar.h>
#include <cstdio>
#include <strsafe.h>


#include <string>
#include <iostream>
#include <array>

#define BUFSIZE 65536 // 16384

class JuliaProcess {

    struct {
        std::array<uint8_t, BUFSIZE> buffer;
        size_t position;
        size_t available;
    } outputstream = {.buffer ={}, .position = 0, .available = 0};

    struct {
        std::array<uint8_t, BUFSIZE> buffer{};
        size_t position = 0;
        size_t available = 0;
    } inputstream = {.buffer ={}, .position = 0, .available = 0};


    std::array<HANDLE, 2> h_stdin;
    std::array<HANDLE, 2> h_stdout;
    std::array<HANDLE, 2> h_stderr;

    // STD_INPUT_HANDLE

    PROCESS_INFORMATION process_information;

    JuliaProcess(std::array<HANDLE, 2> h_stdin, std::array<HANDLE, 2> h_stdout, std::array<HANDLE, 2> h_stderr, PROCESS_INFORMATION process_information) :
        h_stdin(h_stdin), h_stdout(h_stdout), h_stderr(h_stderr), process_information(process_information)
    {


    }



public:

    ~JuliaProcess() {
        // Close handles to the child process and its primary thread.
        // Some applications might keep these handles to monitor the status
        // of the child process, for example.
        TerminateProcess(process_information.hProcess, 0);

        WaitForSingleObject(process_information.hProcess, 500);

        CloseHandle(process_information.hProcess);
        CloseHandle(process_information.hThread);

        // Close handles to the stdin and stdout pipes no longer needed by the child process.
        // If they are not explicitly closed, there is no way to recognize that the child process has ended.

        CloseHandle(h_stdin[1]);
        CloseHandle(h_stdout[0]);
        CloseHandle(h_stderr[0]);
    }

    void write(const uint8_t* buf, const size_t nb) {
        size_t bw = std::min(outputstream.buffer.size() - outputstream.available, nb);
        memcpy(&outputstream.buffer[outputstream.available], buf, bw);
        outputstream.available += bw;

        if (bw >= nb) {
            return;
        }

        flush();

        while (nb - bw >= outputstream.buffer.size()) {
            DWORD bytes_written = 0;
            WriteFile(
                h_stdin[1],
                &buf[bw],
                outputstream.buffer.size(),
                &bytes_written,
                nullptr);
            bw += bytes_written;
        }

        if (bw < nb) {
            outputstream.position  = 0;
            outputstream.available = nb - bw;
            memcpy(&outputstream.buffer[0], &buf[bw], outputstream.available);
        }
    }

    void flush() {
        while (outputstream.available > outputstream.position) {
            DWORD bytes_written = 0;
            WriteFile(
                h_stdin[1],
                &outputstream.buffer[outputstream.position],
                outputstream.available-outputstream.position,
                &bytes_written,
                nullptr);

            outputstream.position += bytes_written;
        }
        outputstream.position = 0;
        outputstream.available = 0;


    }


    void read(uint8_t* buf, const size_t nb) {
        size_t br = 0;

        while (br < nb) {
            if (inputstream.available - inputstream.position > 0) {
                size_t brn = std::min(inputstream.available - inputstream.position , nb - br);
                memcpy(&buf[br], &inputstream.buffer[inputstream.position], brn);
                inputstream.position += brn;
                br += brn;

            } else if (nb - br >= inputstream.buffer.size()) {
                DWORD bytes_read;
                ReadFile(
                    h_stdout[0],
                    &buf[br],
                    inputstream.buffer.size(),
                    &bytes_read,
                    nullptr);
                br += bytes_read;
            } else {
                DWORD bytes_read;

                ReadFile(
                    h_stdout[0],
                    &inputstream.buffer[0],
                    inputstream.buffer.size(),
                    &bytes_read,
                    nullptr);

                inputstream.position = 0;
                inputstream.available = bytes_read;

            }


        }

    };


    static JuliaProcess spawn(const std::string& bin, const std::string& project) {
        // TCHAR szCmdline[]=TEXT("C:\\Users\\jbelier\\.julia\\juliaup\\julia-1.12.0-rc1+0.x64.w64.mingw32\\bin\\julia.exe -e \"println(read(stdin, Int64))\"");

        std::string cmdline = "\"" + bin + "\" --project=\"" + project + "\" -e \"using MATFrostDev ; MATFrostDev.serve()\"";//read(stdin, Int64))\"";

        SECURITY_ATTRIBUTES saAttr;

        printf("\n->Start of parent execution.\n");

        // Set the bInheritHandle flag so pipe handles are inherited.


        saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
        saAttr.bInheritHandle = TRUE;
        saAttr.lpSecurityDescriptor = NULL;

        std::array<HANDLE, 2> h_stdin{};
        std::array<HANDLE, 2> h_stdout{};
        std::array<HANDLE, 2> h_stderr{};

        if ( ! CreatePipe(&h_stdin[0], &h_stdin[1], &saAttr, 4*BUFSIZE) ) {
            // ErrorExit(TEXT("StdoutRd CreatePipe"));
        }
        if ( ! SetHandleInformation(&h_stdin[1], HANDLE_FLAG_INHERIT, 0) ) {
            // ErrorExit(TEXT("Stdout SetHandleInformation"));
        }

        if ( ! CreatePipe(&h_stdout[0], &h_stdout[1], &saAttr, 4*BUFSIZE) ) {
            // ErrorExit(TEXT("StdoutRd CreatePipe"));
        }
        if ( ! SetHandleInformation(&h_stdout[0], HANDLE_FLAG_INHERIT, 0) ) {
            // ErrorExit(TEXT("Stdout SetHandleInformation"));
        }

        if ( ! CreatePipe(&h_stderr[0], &h_stderr[1], &saAttr, 4*BUFSIZE) ) {
            // ErrorExit(TEXT("StdoutRd CreatePipe"));
        }
        if ( ! SetHandleInformation(&h_stderr[0], HANDLE_FLAG_INHERIT, 0) ) {
            // ErrorExit(TEXT("Stdout SetHandleInformation"));
        }

        std::cout << "HANDLE stdin.Read: " << h_stdin[0] << " stdin.Write:" << h_stdin[1] << std::endl;




        PROCESS_INFORMATION piProcInfo;
        STARTUPINFO siStartInfo;
        ZeroMemory( &piProcInfo, sizeof(PROCESS_INFORMATION) );
        ZeroMemory( &siStartInfo, sizeof(STARTUPINFO) );


        // Set up members of the PROCESS_INFORMATION structure.


        siStartInfo.cb = sizeof(STARTUPINFO);
        siStartInfo.hStdInput  = h_stdin[0];
        siStartInfo.hStdOutput = h_stdout[1];
        siStartInfo.hStdError  = h_stderr[1];
        siStartInfo.dwFlags |= STARTF_USESTDHANDLES;

        // Create the child process.

        CreateProcessA(
          bin.c_str(),
          &cmdline[0],   // command line
          nullptr,       // process security attributes
          nullptr,       // primary thread security attributes
          TRUE,          // handles are inherited
          0,             // creation flags
          nullptr,       // use parent's environment
          nullptr,       // use parent's current directory
          &siStartInfo,  // STARTUPINFO pointer
          &piProcInfo);  // receives PROCESS_INFORMATION


        CloseHandle(h_stdin[0]);
        CloseHandle(h_stdout[1]);
        CloseHandle(h_stderr[1]);


        const JuliaProcess jp(h_stdin, h_stdout, h_stderr, piProcInfo);

        return jp;

    }



};
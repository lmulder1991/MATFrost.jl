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

class BufferedOutputStream {
    std::array<uint8_t, BUFSIZE> buffer{};
    size_t position = 0;
    size_t available = 0;

    HANDLE handle = nullptr;

public:

    explicit BufferedOutputStream(HANDLE h) : handle(h) {}

    ~BufferedOutputStream() {
        CloseHandle(handle);
    }

    void write(const uint8_t* data, const size_t nb) {
        size_t bw = std::min(BUFSIZE - available, nb);
        memcpy(&buffer[available], data, bw);
        available += bw;

        if (bw >= nb) {
            return;
        }

        flush();

        while (nb - bw >= BUFSIZE) {
            DWORD bytes_written = 0;
            WriteFile(
                handle,
                &data[bw],
                BUFSIZE,
                &bytes_written,
                nullptr);
            bw += bytes_written;
        }

        if (bw < nb) {
            position  = 0;
            available = nb - bw;
            memcpy(&buffer[0], &data[bw], available);
        }
    }

    void flush() {
        while (available > position) {
            DWORD bytes_written = 0;
            WriteFile(
                handle,
                &buffer[position],
                available-position,
                &bytes_written,
                nullptr);

            position += bytes_written;
        }
        position = 0;
        available = 0;


    }
};

class BufferedInputStream {
    std::array<uint8_t, BUFSIZE> buffer{};
    size_t position;
    size_t available;

    HANDLE handle = nullptr;

public:

    explicit BufferedInputStream(HANDLE h) : handle(h), position(0), available(0) {
    }

    ~BufferedInputStream() {
        CloseHandle(handle);
    }

    void read(uint8_t* data, const size_t nb) {
        size_t br = 0;

        while (br < nb) {
            if (available - position > 0) {
                size_t brn = std::min(available - position , nb - br);
                memcpy(&data[br], &buffer[position], brn);
                position += brn;
                br += brn;

            } else if (nb - br >= BUFSIZE) {
                DWORD bytes_read;
                ReadFile(
                    handle,
                    &data[br],
                    BUFSIZE,
                    &bytes_read,
                    nullptr);
                br += bytes_read;
            } else {
                DWORD bytes_read;

                ReadFile(
                    handle,
                    &buffer[0],
                    BUFSIZE,
                    &bytes_read,
                    nullptr);

                position = 0;
                available = bytes_read;

            }


        }

    };

};

class JuliaProcess {

public:


    BufferedInputStream inputstream;
    BufferedOutputStream outputstream;
    BufferedInputStream errorstream;

    PROCESS_INFORMATION process_information;

    JuliaProcess(HANDLE inputstream_h, HANDLE errorstream_h, HANDLE outputstream_h, PROCESS_INFORMATION process_information) :
        process_information(process_information),
        inputstream(BufferedInputStream(inputstream_h)),
        outputstream(BufferedOutputStream(outputstream_h)),
        errorstream(BufferedInputStream(errorstream_h))
    {

    }


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
        //

    }






    static JuliaProcess spawn(const std::string& bin, const std::string& project) {
        // TCHAR szCmdline[]=TEXT("C:\\Users\\jbelier\\.julia\\juliaup\\julia-1.12.0-rc1+0.x64.w64.mingw32\\bin\\julia.exe -e \"println(read(stdin, Int64))\"");


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

        std::string cmdline = "\"" + bin + "\" --project=\"" + project + "\" -e \"using MATFrost ; MATFrost.serve(" +
            std::to_string((long long) h_stdin[0]) + ", "+ std::to_string((long long) h_stdout[1]) +")\"";//read(stdin, Int64))\"";



        PROCESS_INFORMATION piProcInfo;
        STARTUPINFO siStartInfo;
        ZeroMemory( &piProcInfo, sizeof(PROCESS_INFORMATION) );
        ZeroMemory( &siStartInfo, sizeof(STARTUPINFO) );


        // Set up members of the PROCESS_INFORMATION structure.


        siStartInfo.cb = sizeof(STARTUPINFO);
        // siStartInfo.hStdInput  = h_stdin[0];
        // siStartInfo.hStdOutput = h_stdout[1];
        siStartInfo.hStdError  = h_stderr[1];
        siStartInfo.dwFlags |= STARTF_USESTDHANDLES;

        // Create the child process.

        CreateProcessA(
          bin.c_str(),
          &cmdline[0],   // command line
          nullptr,       // process security attributes
          nullptr,       // primary thread security attributes
          TRUE,          // handles are inherited
          CREATE_NO_WINDOW,             // creation flags
          nullptr,       // use parent's environment
          nullptr,       // use parent's current directory
          &siStartInfo,  // STARTUPINFO pointer
          &piProcInfo);  // receives PROCESS_INFORMATION


        CloseHandle(h_stdin[0]);
        CloseHandle(h_stdout[1]);
        CloseHandle(h_stderr[1]);



        const JuliaProcess jp(
            h_stdout[0],
            h_stderr[0],
            h_stdin[1], piProcInfo);

        return jp;

    }



};
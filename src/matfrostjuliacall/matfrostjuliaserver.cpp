/**
 * This file is responsible of managing the Julia process and offer a communication interface over pipes with the Julia
 * process. This class is free of MATLAB dependencies
 */
#include <cstdint>
#include <windows.h>
#include <tchar.h>
#include <cstdio>
#include <strsafe.h>


#include <memory>

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
    size_t buf_available;

    HANDLE handle = nullptr;

public:

    explicit BufferedInputStream(HANDLE h) : handle(h), position(0), buf_available(0) {
    }

    ~BufferedInputStream() {
        CloseHandle(handle);
    }

    void read(uint8_t* data, const size_t nb) {
        size_t br = 0;

        while (br < nb) {
            if (buf_available - position > 0) {
                size_t brn = std::min(buf_available - position , nb - br);
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
                buf_available = bytes_read;

            }


        }

    };

    bool available() {
        if (buf_available - position > 0) {
            return true;
        }

        DWORD bytes_available;
        if (PeekNamedPipe(handle, nullptr, 0, nullptr, &bytes_available, nullptr)) {
            return bytes_available > 0;
        }
        return false;
    }


};

class JuliaProcess {

public:


    BufferedInputStream inputstream;
    BufferedOutputStream outputstream;

    BufferedOutputStream stdinstream;
    BufferedInputStream stdoutstream;
    BufferedInputStream stderrstream;

    PROCESS_INFORMATION process_information;

    JuliaProcess(PROCESS_INFORMATION process_information, HANDLE inputstream_h, HANDLE outputstream_h, HANDLE stdinstream_h, HANDLE stdoutstream_h, HANDLE stderrstream_h) :
        process_information(process_information),
        inputstream(BufferedInputStream(inputstream_h)),
        outputstream(BufferedOutputStream(outputstream_h)),

        stdinstream(BufferedOutputStream(stdinstream_h)),
        stdoutstream(BufferedInputStream(stdoutstream_h)),
        stderrstream(BufferedInputStream(stderrstream_h))

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
    //

    bool callable() {
        DWORD exit_code;
        GetExitCodeProcess(process_information.hProcess, &exit_code);
        return exit_code == STILL_ACTIVE;
    }





    static std::shared_ptr<JuliaProcess> spawn(const std::string& cmdline) {

        SECURITY_ATTRIBUTES saAttr;

        saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
        saAttr.bInheritHandle = TRUE;
        saAttr.lpSecurityDescriptor = NULL;


        std::array<HANDLE, 2> h_input{};
        std::array<HANDLE, 2> h_output{};

        std::array<HANDLE, 2> h_stdin{};
        std::array<HANDLE, 2> h_stdout{};
        std::array<HANDLE, 2> h_stderr{};

        std::array<std::array<HANDLE, 2>*, 5> pipes = {&h_input, &h_output, &h_stdin, &h_stdout, &h_stderr};
        std::array<size_t, 5> disable_inheritance = {0, 1, 1, 0, 0};

        // std::array<std::array<HANDLE, 2>&, 5> PIPESET2 = {h_input, h_output, h_stdin, h_stdout, h_stderr};

        for (size_t i = 0; i < 5; i++) {
            std::array<HANDLE, 2>& pipe_r = *pipes[i];
            if ( ! CreatePipe(&pipe_r[0], &pipe_r[1], &saAttr, 4*BUFSIZE) ) {
                // ErrorExit(TEXT("StdoutRd CreatePipe"));
            }
            if ( ! SetHandleInformation(&pipe_r[disable_inheritance[i]], HANDLE_FLAG_INHERIT, 0) ) {
                // ErrorExit(TEXT("Stdout SetHandleInformation"));
            }
        }



        // std::cout << "HANDLE stdin.Read: " << h_stdin[0] << " stdin.Write:" << h_stdin[1] << std::endl;
        //
        std::string cmdline_pipes = cmdline + " " +
            std::to_string(reinterpret_cast<size_t>(h_output[0])) + " " + std::to_string(reinterpret_cast<size_t>(h_input[1]));



        PROCESS_INFORMATION piProcInfo;
        STARTUPINFO siStartInfo;
        ZeroMemory( &piProcInfo, sizeof(PROCESS_INFORMATION) );
        ZeroMemory( &siStartInfo, sizeof(STARTUPINFO) );


        // Set up members of the PROCESS_INFORMATION structure.


        siStartInfo.cb = sizeof(STARTUPINFO);
        siStartInfo.hStdInput = h_stdin[0];
        siStartInfo.hStdOutput = h_stdout[1];
        siStartInfo.hStdError  = h_stderr[1];
        siStartInfo.dwFlags |= STARTF_USESTDHANDLES;

        // Create the child process.

        CreateProcessA(
          nullptr,
          &cmdline_pipes[0],   // command line
          nullptr,       // process security attributes
          nullptr,       // primary thread security attributes
          TRUE,          // handles are inherited
          CREATE_NO_WINDOW,             // creation flags
          nullptr,       // use parent's environment
          nullptr,       // use parent's current directory
          &siStartInfo,  // STARTUPINFO pointer
          &piProcInfo);  // receives PROCESS_INFORMATION


        CloseHandle(h_input[1]);
        CloseHandle(h_output[0]);

        CloseHandle(h_stdin[0]);
        CloseHandle(h_stdout[1]);
        CloseHandle(h_stderr[1]);



        return std::make_shared<JuliaProcess>(
            piProcInfo,

            h_input[0],
            h_output[1],

            h_stdin[1],
            h_stdout[0],
            h_stderr[0]);


    }



};
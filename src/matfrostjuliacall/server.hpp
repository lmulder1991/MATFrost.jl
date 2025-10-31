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

namespace MATFrost {
    class MATFrostServer {

    public:

        PROCESS_INFORMATION process_information;

        MATFrostServer(PROCESS_INFORMATION process_information) :
            process_information(process_information)
        {

        }


        ~MATFrostServer() {
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

        bool is_alive() {
            DWORD exit_code;
            GetExitCodeProcess(process_information.hProcess, &exit_code);
            return exit_code == STILL_ACTIVE;
        }

        static std::shared_ptr<MATFrostServer> spawn(const std::string cmdline) {

            SECURITY_ATTRIBUTES saAttr;

            saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
            saAttr.bInheritHandle = TRUE;
            saAttr.lpSecurityDescriptor = NULL;

            std::string cmdline_pipes = cmdline;

            PROCESS_INFORMATION piProcInfo;
            STARTUPINFO siStartInfo;
            ZeroMemory( &piProcInfo, sizeof(PROCESS_INFORMATION) );
            ZeroMemory( &siStartInfo, sizeof(STARTUPINFO) );

            // Set up members of the PROCESS_INFORMATION structure.


            siStartInfo.cb = sizeof(STARTUPINFO);
            // siStartInfo.hStdInput = h_stdin[0];
            // siStartInfo.hStdOutput = h_stdout[1];
            // siStartInfo.hStdError  = h_stderr[1];
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

            return std::make_shared<MATFrostServer>(piProcInfo);


        }

    };
}






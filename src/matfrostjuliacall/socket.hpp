//
// Created by jbelier on 19/10/2025.
//

#ifndef MATFROST_JL_SOCKET_HPP
#define MATFROST_JL_SOCKET_HPP

#include <cstdint>
#include <winsock2.h>
#include <windows.h>
#include <tchar.h>
#include <cstdio>
#include <strsafe.h>

#include <afunix.h>
// #define UNIX_PATH_MAX 108
//
// typedef struct sockaddr_un
// {
//     uint16_t sun_family;     /* AF_UNIX */
//     char sun_path[UNIX_PATH_MAX];  /* pathname */
// } SOCKADDR_UN;


#include <memory>

#include <string>
#include <iostream>
#include <array>

#define BUFSIZE 65536 // 16384

namespace MATFrost::Socket {

    bool wsa_initialized = false;
    WSADATA wsa_data = { 0 };


    struct Buffer {
        std::array<uint8_t, BUFSIZE> data{};
        size_t position = 0;
        size_t available = 0;
    };


    class BufferedUnixDomainSocket {
        const std::string socket_path;
        SOCKET socket_fd = INVALID_SOCKET;

        Buffer input{};
        Buffer output{};

    public:
        BufferedUnixDomainSocket(const std::string &socket_path, SOCKET socket) : socket_path(socket_path), socket_fd(socket) {

        }

        ~BufferedUnixDomainSocket() {
            if (socket_fd != INVALID_SOCKET) {
                closesocket(socket_fd);
            }
        }


        void read(uint8_t *data, const size_t nb) {
            size_t br = 0;

            while (br < nb) {
                if (input.available - input.position > 0) {
                    size_t brn = std::min(input.available - input.position, nb - br);
                    memcpy(&data[br], &input.data[input.position], brn);
                    input.position += brn;
                    br += brn;
                } else if (nb - br >= BUFSIZE) {
                    auto brn = recv(
                        socket_fd,
                        reinterpret_cast<char *>(&data[br]),
                        BUFSIZE,
                        0);
                    br += brn;
                } else {
                    auto brn = recv(
                        socket_fd,
                        reinterpret_cast<char *>(&input.data[0]),
                        BUFSIZE,
                        0);

                    input.position = 0;
                    input.available = brn;
                }
            }
        };


        void write(const uint8_t *data, const size_t nb) {
            size_t bw = std::min(BUFSIZE - output.available, nb);
            memcpy(&output.data[output.available], data, bw);
            output.available += bw;

            if (bw >= nb) {
                return;
            }

            flush();

            while (nb - bw >= BUFSIZE) {
                bw += send(
                    socket_fd,
                    reinterpret_cast<const char *>(&data[bw]),
                    BUFSIZE,
                    0);
            }

            if (bw < nb) {
                output.position = 0;
                output.available = nb - bw;
                memcpy(&output.data[0], &data[bw], output.available);
            }
        }

        void flush() {
            while (output.available > output.position) {
                output.position += send(
                    socket_fd,
                    reinterpret_cast<const char *>(&output.data[output.position]),
                    output.available - output.position,
                    0);
            }
            output.position = 0;
            output.available = 0;
        }

        static std::shared_ptr<BufferedUnixDomainSocket> connect_socket(const std::string socket_path) {
            if (!wsa_initialized) {
                int rc = WSAStartup(MAKEWORD(2, 2), &wsa_data);
                wsa_initialized = true;
            }

            SOCKET socket_fd = socket(AF_UNIX, SOCK_STREAM, 0);
            if (socket_fd == INVALID_SOCKET) {
                printf("socket() error: %d\n", WSAGetLastError());
                throw(matlab::engine::MATLABException("ERROR: create socket: \n"));
            }
            // getsockopt(socket_fd, SOL_SOCKET, SO_SNDBUF, (char*)&sndbuf_size, &optlen);
            // getsockopt(socket_fd, SOL_SOCKET, SO_RCVBUF, (char*)&rcvbuf_size, &optlen);


            // write(socket_fd,

            SOCKADDR_UN socket_addr = {0};
            socket_addr.sun_family = AF_UNIX;
            strncpy_s(socket_addr.sun_path, sizeof socket_addr.sun_path, socket_path.c_str(), (socket_path.length()));


            int rc = connect(socket_fd, reinterpret_cast<struct sockaddr *>(&socket_addr), sizeof(socket_addr));

            if (rc == SOCKET_ERROR) {
                // printf("connect() error: %d\n", WSAGetLastError());
                throw(matlab::engine::MATLABException("ERROR: create connection: \n"));
            }

            return std::make_shared<BufferedUnixDomainSocket>(socket_path, socket_fd);

        }
    };
}


#endif //MATFROST_JL_SOCKET_HPP
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

        timeval timeout = {5, 0};

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
                    br += read_from_socket(&data[br], BUFSIZE);;
                } else {
                    input.position = 0;
                    input.available = read_from_socket(&input.data[0], BUFSIZE);
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
                bw += write_to_socket(&data[bw], BUFSIZE);
            }

            if (bw < nb) {
                output.position = 0;
                output.available = nb - bw;
                memcpy(&output.data[0], &data[bw], output.available);
            }
        }

        void flush() {
            while (output.available > output.position) {
                output.position += write_to_socket(&output.data[output.position], output.available - output.position);
            }
            output.position = 0;
            output.available = 0;
        }

        int write_to_socket(const uint8_t *data, const size_t nb) {

            if (!wait_for_writable()) {
                throw matlab::engine::MATLABException("Write timeout");
            }

            int sent = send(socket_fd,
                reinterpret_cast<const char*>(data),
                static_cast<int>(nb),
                0);

            if (sent > 0) {
                return sent;
                // Might block here on next iteration if buffer fills
            } else if (sent == 0) {
                throw matlab::engine::MATLABException("Connection closed");
            } else {
                throw matlab::engine::MATLABException("Send error: " +
                                       std::to_string(WSAGetLastError()));
            }

        }

        int read_from_socket(uint8_t *data, const int nb) {
            // Use select to wait for data with timeout
            if (!wait_for_readable()) {  // 5 second timeout
                throw matlab::engine::MATLABException("Read timeout: no data available");
            }

            auto brn = recv(
                        socket_fd,
                        reinterpret_cast<char *>(data),
                        nb,
                        0);

            if (brn > 0) {
                return brn;
            } else if (brn == 0) {
                throw matlab::engine::MATLABException("Connection closed by peer during read");
            } else {
                throw matlab::engine::MATLABException("Socket read error: " + std::to_string(WSAGetLastError()));
            }
        }

        bool wait_for_readable() const {
            if (socket_fd == INVALID_SOCKET) {
                return false;
            }

            fd_set read_set, error_set;
            FD_ZERO(&read_set);
            FD_ZERO(&error_set);

            FD_SET(socket_fd, &read_set);
            FD_SET(socket_fd, &error_set);

            // timeval timeout;
            // timeout.tv_sec = timeout_ms / 1000;
            // timeout.tv_usec = (timeout_ms % 1000) * 1000;

            int result = select(0, &read_set, nullptr, &error_set, &timeout);

            if (result == SOCKET_ERROR) {
                return false;
            }

            if (result == 0) {
                // Timeout
                return false;
            }

            // Check for errors
            if (FD_ISSET(socket_fd, &error_set)) {
                return false;
            }

            // Check if data is available
            if (FD_ISSET(socket_fd, &read_set)) {
                // Verify it's not EOF
                char buf[1];
                int peek_result = recv(socket_fd, buf, 1, MSG_PEEK);
                if (peek_result == 0) {
                    // EOF - connection closed
                    return false;
                }
                return true;
            }

            return false;
        }

        bool wait_for_writable() const {
            if (socket_fd == INVALID_SOCKET) {
                return false;
            }

            fd_set write_set, error_set;
            FD_ZERO(&write_set);
            FD_ZERO(&error_set);

            FD_SET(socket_fd, &write_set);
            FD_SET(socket_fd, &error_set);



            int result = select(0, nullptr, &write_set, &error_set, &timeout);

            if (result == SOCKET_ERROR) {
                return false;
            }

            if (result == 0) {
                // Timeout
                return false;
            }

            // Check for errors first
            if (FD_ISSET(socket_fd, &error_set)) {
                return false;
            }

            // Check if writable
            if (FD_ISSET(socket_fd, &write_set)) {
                // Optionally verify connection is still good
                int error = 0;
                int error_len = sizeof(error);
                if (getsockopt(socket_fd, SOL_SOCKET, SO_ERROR,
                              reinterpret_cast<char*>(&error), &error_len) == SOCKET_ERROR) {
                    return false;
                              }
                return error == 0;
            }

            return false;
        }



        bool is_connected() const {
            if (socket_fd == INVALID_SOCKET) {
                return false;
            }

            // Step 1: Check for socket-level errors
            int error = 0;
            int error_len = sizeof(error);
            if (getsockopt(socket_fd, SOL_SOCKET, SO_ERROR,
                           reinterpret_cast<char*>(&error), &error_len) == SOCKET_ERROR) {
                return false;
                           }

            if (error != 0) {
                return false;
            }

            // Step 2: Use recv with MSG_PEEK to check connection status
            // This doesn't consume any data from the socket
            char buf[1];
            int result = recv(socket_fd, buf, 1, MSG_PEEK);

            if (result == 0) {
                // recv() returned 0 = connection closed gracefully by peer
                return false;
            }

            if (result == SOCKET_ERROR) {
                int recv_error = WSAGetLastError();

                // WSAEWOULDBLOCK means no data available but socket is connected
                // This is normal for non-blocking sockets
                if (recv_error == WSAEWOULDBLOCK) {
                    return true;
                }

                // Any other error means connection is broken
                // Common errors: WSAECONNRESET, WSAECONNABORTED, WSAENOTCONN
                return false;
            }

            // result > 0 means data available and socket is connected
            return true;
        }

        static std::shared_ptr<BufferedUnixDomainSocket> connect_socket(const std::string socket_path) {
            if (!wsa_initialized) {
                int rc = WSAStartup(MAKEWORD(2, 2), &wsa_data);
                if (rc != 0) {
                    throw(matlab::engine::MATLABException("WSAStartup failed: " + std::to_string(rc)));
                }
                wsa_initialized = true;
            }

            SOCKADDR_UN socket_addr = {0};
            socket_addr.sun_family = AF_UNIX;
            strncpy_s(socket_addr.sun_path, sizeof socket_addr.sun_path,
                      socket_path.c_str(), socket_path.length());



            for (int attempt = 0; attempt < 400; attempt++) {
                SOCKET socket_fd = socket(AF_UNIX, SOCK_STREAM, 0);
                if (socket_fd == INVALID_SOCKET) {
                    throw(matlab::engine::MATLABException("Failed to create socket: " +
                                                         std::to_string(WSAGetLastError())));
                }

                // // Set non-blocking mode
                // u_long mode = 1;
                // if (ioctlsocket(socket_fd, FIONBIO, &mode) != 0) {
                //     closesocket(socket_fd);
                //     throw(matlab::engine::MATLABException("Failed to set non-blocking mode: " +
                //                                          std::to_string(WSAGetLastError())));
                // }

                // Attempt connection
                int rc = connect(socket_fd, reinterpret_cast<struct sockaddr *>(&socket_addr),
                                sizeof(socket_addr));

                if (rc == 0) {
                    // Connection succeeded immediately
                    return std::make_shared<BufferedUnixDomainSocket>(socket_path, socket_fd);
                }
                closesocket(socket_fd);
                Sleep(100);
                // int error = WSAGetLastError();
                //
                // if (error == WSAEWOULDBLOCK) {
                //     // Connection in progress - wait for completion
                //     fd_set write_set, error_set;
                //     FD_ZERO(&write_set);
                //     FD_ZERO(&error_set);
                //
                //     FD_SET(socket_fd, &write_set);
                //     FD_SET(socket_fd, &error_set);
                //
                //     timeval tv;
                //     tv.tv_sec = 0;
                //     tv.tv_usec = 500000;  // 500ms timeout per attempt
                //
                //     int select_result = select(0, nullptr, &write_set, &error_set, &tv);
                //
                //     if (select_result > 0) {
                //         if (FD_ISSET(socket_fd, &error_set)) {
                //             // Connection failed
                //             closesocket(socket_fd);
                //         } else if (FD_ISSET(socket_fd, &write_set)) {
                //             // Check if connection actually succeeded
                //             int sock_error = 0;
                //             int error_len = sizeof(sock_error);
                //             if (getsockopt(socket_fd, SOL_SOCKET, SO_ERROR,
                //                           reinterpret_cast<char*>(&sock_error), &error_len) == 0) {
                //                 if (sock_error == 0) {
                //                     // Connection successful!
                //                     return std::make_shared<BufferedUnixDomainSocket>(socket_path, socket_fd);
                //                 }
                //             }
                //             closesocket(socket_fd);
                //         }
                //     } else {
                //         // Timeout or error
                //         closesocket(socket_fd);
                //     }
                // } else {
                //     // Connection failed with other error
                //     closesocket(socket_fd);
                // }

                // Wait before retry
                Sleep(100);
            }
            throw(matlab::engine::MATLABException("Connection timeout after " +
                                     std::to_string(40) +
                                     " seconds: " + socket_path));

        }

            //
            // SOCKET socket_fd = socket(AF_UNIX, SOCK_STREAM, 0);
            // if (socket_fd == INVALID_SOCKET) {
            //     printf("socket() error: %d\n", WSAGetLastError());
            //     throw(matlab::engine::MATLABException("ERROR: create socket: \n"));
            // }
            //
            // u_long mode = 1;
            // ioctlsocket(socket_fd, FIONBIO, &mode);
            //
            // // getsockopt(socket_fd, SOL_SOCKET, SO_SNDBUF, (char*)&sndbuf_size, &optlen);
            // // getsockopt(socket_fd, SOL_SOCKET, SO_RCVBUF, (char*)&rcvbuf_size, &optlen);
            //
            //
            // // write(socket_fd,
            //
            // SOCKADDR_UN socket_addr = {0};
            // socket_addr.sun_family = AF_UNIX;
            // strncpy_s(socket_addr.sun_path, sizeof socket_addr.sun_path, socket_path.c_str(), (socket_path.length()));
            //
            // int rc = connect(socket_fd, reinterpret_cast<struct sockaddr *>(&socket_addr), sizeof(socket_addr));
            //
            // if (rc != SOCKET_ERROR) {
            //     // WSAEWOULDBLOCK - connection in progress
            //     // Wait for connection to complete
            //     if (!wait_for_connection(socket_fd, 40000)) {  // 40 second timeout
            //         closesocket(socket_fd);
            //         throw(matlab::engine::MATLABException("Connection timeout: " + socket_path));
            //     }
            // } else {
            //     closesocket(socket_fd);
            //     throw(matlab::engine::MATLABException("Connection error: " + socket_path));
            // }
            // bool started = false;
            // for (size_t i = 0; i < 400; i++) {
            //
            //     if (rc != SOCKET_ERROR) {
            //         started = true;
            //         break;
            //         // printf("connect() error: %d\n", WSAGetLastError());
            //         // throw(matlab::engine::MATLABException("ERROR: create connection: \n"));
            //     } else {
            //         Sleep(100);
            //     }
            // }
            //
            // if (!started) {
            //     throw(matlab::engine::MATLABException("Socket timeout 40s: " + socket_path));
            // }


            // return std::make_shared<BufferedUnixDomainSocket>(socket_path, socket_fd);

        // }


    };
}


#endif //MATFROST_JL_SOCKET_HPP
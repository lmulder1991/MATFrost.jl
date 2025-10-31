
#include <winsock2.h>

#include "mex.hpp"
#include "mexAdapter.hpp"

#include <tuple>
// stdc++ lib
#include <map>
#include <string>

// External dependencies
// using namespace matlab::data;
using matlab::mex::ArgumentList;
#include <thread>
#include <condition_variable>
#include <mutex>

#include <complex>

#include <chrono>

#include "socket.hpp"
#include "server.hpp"
#include "converttojulia.hpp"

#include "converttomatlab.hpp"

#include "controller.hpp"


#define EXPERIMENT_SIZE 1000000


class MexFunction : public matlab::mex::Function {
private:

    std::map<uint64_t, std::shared_ptr<MATFrost::MATFrostServer>> matfrost_server{};
    std::map<uint64_t, std::shared_ptr<MATFrost::Socket::BufferedUnixDomainSocket>> matfrost_connections{};



public:
    MexFunction() {


    }

    ~MexFunction() override {

    }

    void operator()(ArgumentList outputs, ArgumentList inputs) {
        // matlab::data::ArrayFactory factory;
        // std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        // matlabPtr->feval(u"disp", 0, std::vector<matlab::data::Array>
        //           ({ factory.createScalar(("###################################\nStarting\n###################################\n"))}));

        const matlab::data::Struct input = static_cast<const matlab::data::StructArray>(inputs[0])[0];

        const uint64_t id = static_cast<const matlab::data::TypedArray<uint64_t>>(input["id"])[0];
        const std::u16string action = static_cast<const matlab::data::StringArray>(input["action"])[0];

        if (action == u"START") {
            const std::string cmdline = static_cast<const matlab::data::StringArray>(input["cmdline"])[0];

            if (matfrost_server.find(id) == matfrost_server.end()) {
                matfrost_server[id] = MATFrost::MATFrostServer::spawn(cmdline);
            }
        } else if (action == u"CONNECT") {
            const std::string socket_path = static_cast<const matlab::data::StringArray>(input["socket"])[0];
            const uint64_t timeout = static_cast<const matlab::data::TypedArray<uint64_t>>(input["timeout"])[0];

            if (matfrost_connections.find(id) == matfrost_connections.end()) {
                auto socket = MATFrost::Socket::BufferedUnixDomainSocket::connect_socket(socket_path, timeout);
                matfrost_connections[id] = socket;
            }
        }
        else if (action == u"STOP") {
            if (matfrost_connections.find(id) != matfrost_connections.end()) {
                matfrost_connections.erase(id);
            }
        }
        else if (action == u"CALL") {
            const matlab::data::StringArray fully_qualified_name = input["fully_qualified_name"];
            const matlab::data::CellArray args = input["args"];

            if (matfrost_connections.find(id) == matfrost_connections.end()) {

            } else {

                auto socket = matfrost_connections[id];

                matlab::data::ArrayFactory factory;

                matlab::data::StructArray callmeta = factory.createStructArray({1}, {"fully_qualified_name"});
                callmeta[0]["fully_qualified_name"] = fully_qualified_name;

                matlab::data::CellArray callstruct = factory.createCellArray({2});
                callstruct[0] = callmeta;
                callstruct[1] = args;

                outputs[0] = juliacall(socket, callstruct);


            }




        }


    }

    matlab::data::Array juliacall(const std::shared_ptr<MATFrost::Socket::BufferedUnixDomainSocket> socket, const matlab::data::Array callstruct) {
        matlab::data::ArrayFactory factory;

        if (!socket->is_connected()) {
            throw(matlab::engine::MATLABException("MATFrost server disconnected"));
        }

        MATFrost::ConvertToJulia::write(socket, callstruct);

        socket->flush();

        return MATFrost::ConvertToMATLAB::read(socket);


    }



};

// class
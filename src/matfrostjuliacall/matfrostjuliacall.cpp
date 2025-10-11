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

#include "matfrostjuliaserver.cpp"
#include "converttojulia.hpp"

#include "converttomatlab.hpp"

#include "matfrostjuliaservercontroller.hpp"


#define EXPERIMENT_SIZE 1000000


class MexFunction : public matlab::mex::Function {
private:


    std::map<uint64_t, std::shared_ptr<MATFrost::Controller::MATFrostServerController>> matfrost_server{};


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

        if (action == u"CREATE") {
            const std::string cmdline = static_cast<const matlab::data::StringArray>(input["cmdline"])[0];

            if (matfrost_server.find(id) == matfrost_server.end()) {
                auto jp = JuliaProcess::spawn(cmdline);
                matfrost_server[id] = MATFrost::Controller::construct_controller(jp);
            }
        }
        else if (action == u"DESTROY") {
            if (matfrost_server.find(id) != matfrost_server.end()) {
                matfrost_server.erase(id);
            }
        }
        else if (action == u"CALL") {
            const matlab::data::StringArray fully_qualified_name = input["fully_qualified_name"];
            const matlab::data::CellArray args = input["args"];

            if (matfrost_server.find(id) == matfrost_server.end()) {

            } else {

                auto ms = matfrost_server[id];


                matlab::data::ArrayFactory factory;


                matlab::data::StructArray callmeta = factory.createStructArray({1}, {"fully_qualified_name"});
                callmeta[0]["fully_qualified_name"] = fully_qualified_name;

                matlab::data::CellArray callstruct = factory.createCellArray({2});
                callstruct[0] = callmeta;
                callstruct[1] = args;

                outputs[0] = juliacall(ms, callstruct);


            }




        }


    }

    matlab::data::Array juliacall(std::shared_ptr<MATFrost::Controller::MATFrostServerController> matfrost_controller, const matlab::data::Array callstruct) {
        matlab::data::ArrayFactory factory;
        std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
        matlabPtr->feval(u"disp", 0, std::vector<matlab::data::Array>
                  ({ factory.createScalar(("###################################\nStarting\n###################################\n"))}));


        if (!matfrost_controller->matfrostserver->callable()) {
            return factory.createScalar(-1);
        }

        return MATFrost::Controller::callsequence(matfrost_controller, callstruct);
        // matlabPtr->feval(u"disp", 0, std::vector<matlab::data::Array>
        //           ({ factory.createScalar(("###################################\ncallable\n###################################\n"))}));
        //
        // // MATFrost::ConvertToJulia::write(callstruct, jp->outputstream);
        // // msc->matfrostserver->outputstream.flush();
        //
        // matlabPtr->feval(u"disp", 0, std::vector<matlab::data::Array>
        //   ({ factory.createScalar(("###################################\nwritten\n###################################\n"))}));
        //
        // while (!jp->inputstream.available()) {
        //     std::this_thread::sleep_for(std::chrono::milliseconds(10));
        // }
        //
        // matlabPtr->feval(u"disp", 0, std::vector<matlab::data::Array>
        //   ({ factory.createScalar(("###################################\nreading\n###################################\n"))}));
        //
        // return MATFrost::ConvertToMATLAB::read(jp->inputstream);

  //       matlabPtr->feval(u"disp", 0, std::vector<matlab::data::Array>
  // ({ factory.createScalar(("###################################\nread\n###################################\n"))}));
    }



};

// class
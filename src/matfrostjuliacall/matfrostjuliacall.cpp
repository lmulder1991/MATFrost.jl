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


#define EXPERIMENT_SIZE 1000000


class MexFunction : public matlab::mex::Function {
private:


    std::map<uint64_t, std::shared_ptr<JuliaProcess>> julia_processes{};


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

        uint64_t id = static_cast<const matlab::data::TypedArray<uint64_t>>(input["id"])[0];
        const std::u16string action = static_cast<const matlab::data::StringArray>(input["action"])[0];

        if (action == u"CREATE") {
            const std::string cmdline = static_cast<const matlab::data::StringArray>(input["cmdline"])[0];

            if (julia_processes.find(id) == julia_processes.end()) {

                julia_processes[id] = std::make_shared<JuliaProcess>(JuliaProcess::spawn(cmdline));
            }
        }
        else if (action == u"DESTROY") {

        }
        else if (action == u"CALL") {

        }


    }



};

// class
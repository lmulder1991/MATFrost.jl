#include <thread>
#include <condition_variable>
#include <mutex>

#include <chrono>
//
// #include "converttojulia.hpp"
// #include "converttomatlab.hpp"
// #include "matfrostjuliaserver.cpp"

namespace MATFrost::Controller {

    matlab::data::Array call_sequence(const std::shared_ptr<MATFrost::Socket::BufferedUnixDomainSocket> socket, const matlab::data::Array input) {
        matlab::data::ArrayFactory factory;

        MATFrost::Write::write(socket, input);
        socket->flush();

        return MATFrost::Read::read(socket);

    }

    // enum MATLAB_ACTION {NOTHING, CALL, LOG, CONTROL};
    //
    // class MATFrostServerController {
    //
    // public:
    //     struct {
    //         std::mutex mtx;
    //         std::condition_variable cv;
    //         matlab::data::Array input{};
    //         matlab::data::Array output{};
    //         std::thread thread{};
    //     } call;
    //
    //     struct {
    //         std::mutex worker_mtx;
    //         std::mutex mtx;
    //         std::condition_variable cv;
    //         MATLAB_ACTION action = MATLAB_ACTION::NOTHING;
    //     } matlab;
    //
    //     struct {
    //         std::string log{};
    //     } log;
    //
    //     struct {
    //
    //     } controller;
    //
    //
    //     std::shared_ptr<MATFrostServer> matfrostserver;
    //
    //     explicit MATFrostServerController(std::shared_ptr<MATFrostServer> matfrostserver) : matfrostserver(matfrostserver) {}
    // };
    //
    //
    // void call_worker(const std::shared_ptr<MATFrostServerController> matfrostcontroller) {
    //     matlab::data::ArrayFactory factory;
    //
    //     std::unique_lock<std::mutex> call_lock{matfrostcontroller->call.mtx};
    //
    //     while (true) {
    //         //-------------------------------
    //         // Julia Call
    //         //-------------------------------
    //
    //         // 1. Wait for call request
    //         matfrostcontroller->call.cv.wait(call_lock, [matfrostcontroller]() {
    //             return !matfrostcontroller->call.input.isEmpty();
    //         });
    //
    //         // 2. Send call to Julia
    //         MATFrost::ConvertToJulia::write(matfrostcontroller->call.input, matfrostcontroller->matfrostserver->outputstream);
    //         matfrostcontroller->matfrostserver->outputstream.flush();
    //         matfrostcontroller->call.input = factory.createEmptyArray();
    //
    //         // 3. Read result from Julia
    //         matfrostcontroller->call.output = MATFrost::ConvertToMATLAB::read(matfrostcontroller->matfrostserver->inputstream);
    //
    //         //-------------------------------
    //         // Send result to MATLAB thread
    //         //-------------------------------
    //
    //         // 1. Single worker thread able to communicate with MATLAB thread.
    //         std::lock_guard<std::mutex> worker_lock{matfrostcontroller->matlab.worker_mtx};
    //
    //         // 2. Start communication with MATLAB thread
    //         std::unique_lock<std::mutex> matlab_lock{matfrostcontroller->matlab.mtx};
    //         matfrostcontroller->matlab.action = MATLAB_ACTION::CALL;
    //
    //         // 3. Give ownership to MATLAB thread
    //         matlab_lock.unlock();
    //         matfrostcontroller->matlab.cv.notify_one();
    //
    //         // 4. Operation finished
    //         matlab_lock.lock();
    //         matfrostcontroller->matlab.cv.wait(matlab_lock, [matfrostcontroller]() {
    //             return matfrostcontroller->matlab.action == MATLAB_ACTION::NOTHING;
    //         });
    //
    //
    //
    //
    //
    //     }
    //
    // }
    //
    // void log_worker(std::shared_ptr<MATFrostServerController> matfrostcontroller) {
    //
    // }
    //
    // void control_worker(std::shared_ptr<MATFrostServerController> matfrostcontroller) {
    //     while (true) {
    //         if (!matfrostcontroller->matfrostserver->is_alive()) {
    //
    //         }
    //         std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    //     }
    // }
    //
    // std::shared_ptr<MATFrostServerController> construct_controller(const std::shared_ptr<MATFrostServer> matfrost_server) {
    //     const std::shared_ptr<MATFrostServerController> matfrost_controller = std::make_shared<MATFrostServerController>(matfrost_server);
    //
    //     std::thread call_thread(call_worker, matfrost_controller);
    //     call_thread.detach();
    //     return matfrost_controller;
    // }
    //
    //
    // matlab::data::Array call_sequence(const std::shared_ptr<MATFrostServerController> matfrost_controller, const matlab::data::Array input) {
    //     matlab::data::ArrayFactory factory;
    //
    //     {
    //         std::unique_lock<std::mutex> lock{matfrost_controller->call.mtx};
    //         matfrost_controller->call.input = input;
    //         lock.unlock();
    //         matfrost_controller->call.cv.notify_one();
    //     }
    //
    //     std::unique_lock<std::mutex> lock{matfrost_controller->matlab.mtx};
    //
    //     while (true) {
    //
    //         matfrost_controller->matlab.cv.wait(lock, [matfrost_controller]() {
    //             return matfrost_controller->matlab.action != MATLAB_ACTION::NOTHING;
    //         });
    //
    //         if (matfrost_controller->matlab.action == MATLAB_ACTION::CALL) {
    //             matlab::data::Array arr = matfrost_controller->call.output;
    //             matfrost_controller->matlab.action = MATLAB_ACTION::NOTHING;
    //             lock.unlock();
    //             matfrost_controller->matlab.cv.notify_one();
    //             return arr;
    //         } else {
    //             matfrost_controller->matlab.action = MATLAB_ACTION::NOTHING;
    //             lock.unlock();
    //             matfrost_controller->matlab.cv.notify_one();
    //         }
    //
    //
    //
    //
    //
    //     }
    // }





}
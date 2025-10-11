#include <thread>
#include <condition_variable>
#include <mutex>

//
// #include "converttojulia.hpp"
// #include "converttomatlab.hpp"
// #include "matfrostjuliaserver.cpp"

namespace MATFrost::Controller {

    enum MATLAB_ACTION {NOTHING, CALL, LOG, CONTROL};

    class MATFrostServerController {

    public:
        struct {
            std::mutex mtx;
            std::condition_variable cv;
            matlab::data::Array input{};
            matlab::data::Array output{};
        } call;

        struct {
            std::mutex worker_mtx;
            std::mutex mtx;
            std::condition_variable cv;
            MATLAB_ACTION action = MATLAB_ACTION::NOTHING;
        } matlab;

        struct {
            std::string log{};
        } log;

        struct {

        } controller;


        std::shared_ptr<JuliaProcess> matfrostserver;

        explicit MATFrostServerController(std::shared_ptr<JuliaProcess> matfrostserver) : matfrostserver(matfrostserver) {}
    };


    void call_thread(const std::shared_ptr<MATFrostServerController> matfrostcontroller) {
        matlab::data::ArrayFactory factory;

        while (true) {
            {
                std::unique_lock<std::mutex> lock{matfrostcontroller->call.mtx};

                matfrostcontroller->call.cv.wait(lock, [matfrostcontroller]() {
                    return !matfrostcontroller->call.input.isEmpty();
                });

                MATFrost::ConvertToJulia::write(matfrostcontroller->call.input, matfrostcontroller->matfrostserver->outputstream);
                matfrostcontroller->matfrostserver->outputstream.flush();

                matfrostcontroller->call.input = factory.createEmptyArray();
                matfrostcontroller->call.output = MATFrost::ConvertToMATLAB::read(matfrostcontroller->matfrostserver->inputstream);

                lock.unlock();
            }

            std::lock_guard<std::mutex> worker_lock{matfrostcontroller->matlab.worker_mtx};
            {
                std::unique_lock<std::mutex> lock{matfrostcontroller->matlab.mtx};
                matfrostcontroller->matlab.action = MATLAB_ACTION::CALL;
                lock.unlock();

                matfrostcontroller->matlab.cv.notify_one();

                lock.lock();
                matfrostcontroller->matlab.cv.wait(lock, [matfrostcontroller]() {
                    return matfrostcontroller->matlab.action == MATLAB_ACTION::NOTHING;
                });

            }




        }

    }

    void log_thread(std::shared_ptr<MATFrostServerController> matfrostcontroller) {

    }

    void controller_thread(std::shared_ptr<MATFrostServerController> matfrostcontroller) {

    }

    std::shared_ptr<MATFrostServerController> construct_controller(const std::shared_ptr<JuliaProcess> matfrostserver) {
        const std::shared_ptr<MATFrostServerController> matfrostcontroller = std::make_shared<MATFrostServerController>(matfrostserver);

        std::thread ct(call_thread, matfrostcontroller);
        ct.detach();
        return matfrostcontroller;
    }


    matlab::data::Array callsequence(const std::shared_ptr<MATFrostServerController> matfrostcontroller, const matlab::data::Array input) {
        matlab::data::ArrayFactory factory;

        {
            std::unique_lock<std::mutex> lock{matfrostcontroller->call.mtx};
            matfrostcontroller->call.input = input;
            lock.unlock();
            matfrostcontroller->call.cv.notify_one();
        }

        while (true) {
            std::unique_lock<std::mutex> lock{matfrostcontroller->matlab.mtx};
            matfrostcontroller->matlab.cv.wait(lock, [matfrostcontroller]() {
                return matfrostcontroller->matlab.action != MATLAB_ACTION::NOTHING;
            });

            if (matfrostcontroller->matlab.action == MATLAB_ACTION::CALL) {
                matlab::data::Array arr = matfrostcontroller->call.output;
                matfrostcontroller->matlab.action = MATLAB_ACTION::NOTHING;
                lock.unlock();
                matfrostcontroller->matlab.cv.notify_one();
                return arr;
            } else {
                matfrostcontroller->matlab.action = MATLAB_ACTION::NOTHING;
                lock.unlock();
                matfrostcontroller->matlab.cv.notify_one();
            }





        }
    }





}
module;

#include <stdexcept>

export module SampleModule;

export class SampleModule {
public:
    SampleModule() = default;
    virtual ~SampleModule() = default;

    void run() {
        throw std::runtime_error("Unimplemented sample module run");
    }
};
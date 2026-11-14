module;

#include <stdexcept>

export module SampleModule;
/**
 * @objectif Initialize and execute the sample module pipeline.
 * @recommendedUsage Instantiate on the stack and invoke run() inside a try-catch block.
 * @unrecommendedUsage Do not share instances across concurrent thread boundaries without synchronization.
 * @complexity O(1) execution time.
 */
export class sample_module {
public:
    sample_module() = default;
    virtual ~sample_module() = default;

    /**
     * @objectif sample run dump.
     */
    void run() {
        throw std::runtime_error("Unimplemented sample module run");
    }
};
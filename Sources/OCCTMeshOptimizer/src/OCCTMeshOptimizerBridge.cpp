// OCCTMeshOptimizer bridge — C++ implementation.
// v0.1.0 will wire meshoptimizer's QEM decimator through this file.
// See docs/INITIAL_IMPLEMENTATION.md.

#include "OCCTMeshOptimizer.h"

extern "C" {

int32_t OCCTMeshOptimizerABIVersion(void) {
    // Pre-alpha. Real ABI version starts at 1 with v0.1.0.
    return 0;
}

}

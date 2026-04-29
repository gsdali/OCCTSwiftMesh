// OCCTMeshOptimizer — C ABI bridge between Swift and vendored meshoptimizer.
//
// v0.1.0 will expose:
//   - OCCTMeshSimplify
//   - OCCTMeshSimplifyFreeResult
//   - OCCTMeshSimplifyScale
//
// See docs/INITIAL_IMPLEMENTATION.md for the full spec.

#ifndef OCCT_MESH_OPTIMIZER_H
#define OCCT_MESH_OPTIMIZER_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Placeholder symbol. Returns the bridge ABI version so consumers can
/// detect whether they linked against the implemented or pre-alpha layer.
/// Will be removed when v0.1.0 lands.
int32_t OCCTMeshOptimizerABIVersion(void);

#ifdef __cplusplus
}
#endif

#endif

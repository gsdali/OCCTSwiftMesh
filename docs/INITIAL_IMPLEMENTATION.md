# Initial Implementation Prompt — v0.1.0 mesh decimation

This document is the bootstrap brief for a fresh Claude Code session implementing the first release of OCCTSwiftMesh. Hand it (or a pointer to it) to the agent and let it work.

---

## Mission

Implement `Mesh.simplified(_:)` on `OCCTSwift.Mesh` — quadric-error-metric (QEM) decimation backed by [meshoptimizer](https://github.com/zeux/meshoptimizer). Ship as **v0.1.0**.

## Spec

The API shape was locked in [OCCTSwift#92](https://github.com/gsdali/OCCTSwift/issues/92). Reproduced here so this doc is self-contained:

```swift
extension Mesh {
    public struct SimplifyOptions: Sendable {
        /// Exact target triangle count. Either this OR `targetReduction` must be set.
        public var targetTriangleCount: Int?

        /// Ratio of triangles to remove (0.0 = none, 1.0 = all). Either this OR
        /// `targetTriangleCount` must be set.
        public var targetReduction: Double?

        /// If true, edges on the mesh boundary (free edges) are not collapsed.
        /// Default: true.
        public var preserveBoundary: Bool = true

        /// If true, edge collapses that would change the surface's genus
        /// (creating holes, splitting components, merging components) are rejected.
        /// Default: true.
        public var preserveTopology: Bool = true

        /// Optional Hausdorff distance cap. Halts decimation when measured
        /// deviation reaches this value, even if the target count hasn't been hit.
        /// In the same units as the input mesh's vertex coordinates.
        public var maxHausdorffDistance: Double?

        public init(...)  // memberwise init
    }

    /// Decimate this mesh per the given options.
    /// - Returns: a `SimplifiedMesh` with before/after counts and achieved
    ///   Hausdorff distance, or `nil` if options are invalid (e.g. neither
    ///   target set, or both set; targetReduction outside [0, 1]).
    public func simplified(_ options: SimplifyOptions) -> SimplifiedMesh?
}

public struct SimplifiedMesh: Sendable {
    public let mesh: Mesh
    public let beforeTriangleCount: Int
    public let afterTriangleCount: Int

    /// Achieved Hausdorff distance from the input mesh, in input units.
    /// Reported regardless of whether `maxHausdorffDistance` was set.
    public let hausdorffDistance: Double
}
```

### Validation rules (return `nil`)

- Neither `targetTriangleCount` nor `targetReduction` set
- Both set
- `targetTriangleCount` < 1 or > input triangle count
- `targetReduction` outside [0.0, 1.0]
- `maxHausdorffDistance` < 0
- Input mesh is empty (`triangleCount == 0`)

## Implementation plan

### Step 1: Vendor meshoptimizer

1. Latest stable: **v1.1** (verified via `gh release list --repo zeux/meshoptimizer`). Tag confirmed at time of writing — re-verify before downloading.
2. Download: `curl -sL https://github.com/zeux/meshoptimizer/archive/refs/tags/v1.1.tar.gz | tar xz -C /tmp/`
3. Copy:
   ```
   /tmp/meshoptimizer-1.1/src/*    →  Sources/OCCTMeshOptimizer/src/meshoptimizer/
   /tmp/meshoptimizer-1.1/LICENSE.md →  Sources/OCCTMeshOptimizer/src/meshoptimizer/LICENSE.md
   ```
   (meshoptimizer's `LICENSE.md` is at the repo root, not under `src/`. Make sure you grab it.)
4. **Do not modify vendored sources.** If a fix is needed, file upstream first.
5. Update `NOTICE.md`'s "Vendored version" line to `v1.1`.
6. Update `Sources/OCCTMeshOptimizer/src/README.md` (write a short stub) noting the vendored version + last-vendored date.

### Step 2: Bridge layer

Create:
- `Sources/OCCTMeshOptimizer/include/OCCTMeshOptimizer.h`
- `Sources/OCCTMeshOptimizer/src/OCCTMeshOptimizerBridge.cpp`

Header (sketch):

```c
// OCCTMeshOptimizer.h — public C ABI

#ifndef OCCT_MESH_OPTIMIZER_H
#define OCCT_MESH_OPTIMIZER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Result struct returned by reference. Caller owns vertices/indices buffers
// and must free with OCCTMeshSimplifyFreeResult.
typedef struct {
    float* vertices;            // 3 floats per vertex, packed
    uint32_t vertexCount;
    uint32_t* indices;          // 3 indices per triangle, packed
    uint32_t triangleCount;
    double hausdorffDistance;
    uint32_t beforeTriangleCount;
    uint32_t afterTriangleCount;
} OCCTMeshSimplifyResult;

/// Run QEM decimation. Inputs are read-only; output is allocated by the
/// bridge and owned by the caller until OCCTMeshSimplifyFreeResult.
///
/// targetIndexCount is the desired triangle count × 3.
/// targetError is the maximum acceptable error in the same units as vertex
///   coordinates; pass FLT_MAX to disable the error cap.
///
/// Returns true on success; false on invalid input or allocation failure.
bool OCCTMeshSimplify(
    const float* vertices,
    uint32_t vertexCount,
    const uint32_t* indices,
    uint32_t indexCount,
    uint32_t targetIndexCount,
    float targetError,
    bool preserveBoundary,
    bool preserveTopology,
    OCCTMeshSimplifyResult* outResult
);

void OCCTMeshSimplifyFreeResult(OCCTMeshSimplifyResult* result);

/// Returns the bounding-box-diagonal scale factor used by meshoptimizer
/// for relative-error → absolute-error conversion. Useful for translating
/// targetError between unit conventions.
float OCCTMeshSimplifyScale(
    const float* vertices,
    uint32_t vertexCount
);

#ifdef __cplusplus
}
#endif

#endif
```

Implementation pulls from meshoptimizer's API:

- `meshopt_simplify(...)` — the QEM decimator. Returns the new index count (≤ targetIndexCount). Output buffer must be at least `indexCount` in size.
- `meshopt_SimplifyLockBorder` flag — passes through `preserveBoundary`
- For `preserveTopology = false` we'd add `meshopt_SimplifySparse` or relax other flags; for v0.1 we can leave topology preservation hard-on (it's the meshoptimizer default) and treat the option as advisory. Document this in the Swift wrapper.
- `meshopt_simplifyScale(...)` — returns the float scale factor used internally; we call it to compute Hausdorff distance from the result error.

Hausdorff distance computation: meshoptimizer's `result_error` out-param from `meshopt_simplify` is the *relative* error (0..1 of the bounding box diagonal). Multiply by `meshopt_simplifyScale(...)` to get absolute distance.

After decimation:

1. Allocate output `vertices` + `indices` buffers
2. Copy non-orphan vertices: meshoptimizer doesn't compact the vertex array — many vertices become orphans after decimation. Use `meshopt_optimizeVertexFetchRemap` to compute a remap, then `meshopt_remapVertexBuffer` + `meshopt_remapIndexBuffer` to compact.
3. Fill `OCCTMeshSimplifyResult` with the compacted buffers + Hausdorff value + before/after triangle counts

### Step 3: Swift wrapper

Create:
- `Sources/OCCTSwiftMesh/Mesh+Simplify.swift`
- `Sources/OCCTSwiftMesh/SimplifyOptions.swift`
- `Sources/OCCTSwiftMesh/SimplifiedMesh.swift`

`SimplifyOptions` and `SimplifiedMesh` are pure value types per the spec.

`Mesh.simplified(_:)`:

1. Validate options (return `nil` on any rule failure)
2. Resolve target triangle count: from `targetTriangleCount` directly, or `Int(Double(triangleCount) * (1.0 - targetReduction))`
3. Extract vertex/index arrays from `self`. OCCTSwift's `Mesh` exposes:
   - `var triangleCount: Int`
   - `var vertexCount: Int`
   - `var vertices: [SIMD3<Float>]` (or similar — verify against current Mesh.swift)
   - `var indices: [UInt32]`
   (If exact API differs, consult OCCTSwift's `Sources/OCCTSwift/Mesh.swift` to find the right accessors. We pin to OCCTSwift `from: "0.156.0"`.)
4. Convert `targetError`: if `maxHausdorffDistance` is set, divide by `OCCTMeshSimplifyScale(...)` to get relative error; otherwise pass `Float.greatestFiniteMagnitude`.
5. Call `OCCTMeshSimplify(...)`. On `false` return → `nil`.
6. Build a new `Mesh` from the result buffers. **Need to verify how to construct a `Mesh` from raw vertex/index arrays in OCCTSwift v0.156.0.** If there's no public initializer, file an issue against OCCTSwift to add one (low-risk additive change, would ship as v0.156.1) — block this implementation on it.
7. Build `SimplifiedMesh(mesh: ..., beforeTriangleCount: ..., afterTriangleCount: ..., hausdorffDistance: ...)`
8. Call `OCCTMeshSimplifyFreeResult` on the bridge result before returning
9. Return

### Step 4: Tests

`Tests/OCCTSwiftMeshTests/SimplifyTests.swift` covering:

- **Golden case:** simplify a sphere mesh (~5K triangles) to 50% target. Assert: `afterTriangleCount` is within ±5% of `beforeTriangleCount * 0.5`; `hausdorffDistance` is positive but less than ~5% of bounding-box diagonal; output mesh has no degenerate triangles.
- **`targetReduction` path:** simplify same sphere with `targetReduction: 0.5`. Assert similar bounds.
- **`maxHausdorffDistance` cap:** simplify a more aggressive target (e.g. `targetReduction: 0.95`) but with a tight Hausdorff cap. Assert the achieved Hausdorff is close to (but ≤) the cap; the count may not hit the target.
- **`preserveBoundary` semantics:** generate a mesh with free edges (e.g. an open shell — extract the upper hemisphere of a sphere). Decimate aggressively with `preserveBoundary: true`. Assert boundary edge count is preserved.
- **Invalid input rejection:** `targetTriangleCount: nil, targetReduction: nil` → `nil`; both set → `nil`; `targetReduction: -0.1` → `nil`; `targetReduction: 1.5` → `nil`; `targetTriangleCount: 0` → `nil`; empty mesh → `nil`.
- **Round-trip:** simplify and verify the output mesh is itself a valid `Mesh` (can re-mesh, query bounds, etc.).

### Step 5: Ground truth (optional but recommended)

Compile a small C++ ground-truth test (`/tmp/meshopt_v1_test.cpp`) that calls `meshopt_simplify` directly on a known input and verifies the API works as documented before wiring it through the bridge. Mirrors OCCTSwift's `/ground-truth` workflow.

### Step 6: Release

1. README.md status: change "Pre-alpha" → "v0.1.0 ships QEM decimation; see CHANGELOG"
2. README.md: move "Mesh.simplified(_:)" example from "Planned API" to "API"
3. `docs/CHANGELOG.md`: write the v0.1.0 entry
4. `docs/algorithms/decimation.md`: design notes (algorithm choice, edge cases, performance characteristics, vendored-version pin)
5. Commit: `v0.1.0: Mesh.simplified(_:) via vendored meshoptimizer v1.1`
6. Tag: `git tag v0.1.0 && git push origin v0.1.0`
7. GitHub release: `gh release create v0.1.0`
8. Close [OCCTSwiftMesh#1](https://github.com/gsdali/OCCTSwiftMesh/issues/1)
9. Cross-link in [OCCTSwiftScripts#22](https://github.com/gsdali/OCCTSwiftScripts/issues/22) and [OCCTMCP#6](https://github.com/gsdali/OCCTMCP/issues/6) — drop a comment noting the dependency is now satisfied.

## Risks & callouts

- **Vertex compaction.** meshoptimizer's `meshopt_simplify` does not compact the vertex array — orphan vertices remain. Failing to compact will produce technically-valid but bloated output. Use `meshopt_optimizeVertexFetchRemap` + `meshopt_remapVertexBuffer` + `meshopt_remapIndexBuffer`.
- **Hausdorff units.** `meshopt_simplify` returns *relative* error (fraction of bounding-box diagonal). Convert to absolute via `meshopt_simplifyScale`. Easy to get backwards.
- **Mesh construction.** Verify OCCTSwift v0.156.0 exposes a public way to construct a `Mesh` from raw `[SIMD3<Float>]` + `[UInt32]` arrays. If not, file an issue and block on the patch release. If we forced you to write internal-only construction in OCCTSwift, that's a hard architectural smell — escalate before papering over it.
- **`preserveTopology = false`.** Not implemented in v0.1 — the option exists in the API for forward compat. Document this clearly in the Swift wrapper's docstring; consider adding a `// TODO: relax meshopt flags when preserveTopology == false` to the bridge.
- **Empty / degenerate input.** Reject early in Swift; the bridge should not be called with `vertexCount < 3` or `indexCount < 3`.

## Acceptance

- [ ] meshoptimizer v1.1 vendored under `Sources/OCCTMeshOptimizer/src/meshoptimizer/` with LICENSE preserved
- [ ] NOTICE.md updated with vendored version
- [ ] Bridge `OCCTMeshSimplify` + `OCCTMeshSimplifyFreeResult` + `OCCTMeshSimplifyScale` implemented
- [ ] Swift `Mesh.simplified(_:)` + `SimplifyOptions` + `SimplifiedMesh` implemented
- [ ] All test cases in step 4 pass
- [ ] `swift build && swift test` clean
- [ ] README.md, CHANGELOG.md, NOTICE.md updated
- [ ] v0.1.0 tagged + released
- [ ] OCCTSwiftMesh#1 closed
- [ ] OCCTSwiftScripts#22 + OCCTMCP#6 cross-linked

## Bootstrap prompt for the new session

Hand this to the new Claude session:

> You're picking up the v0.1.0 implementation of OCCTSwiftMesh. The repo is at `~/Projects/OCCTSwiftMesh/` (cloned from https://github.com/gsdali/OCCTSwiftMesh). Read `CLAUDE.md` for project conventions, then read `docs/INITIAL_IMPLEMENTATION.md` for the full implementation plan. Issue [#1](https://github.com/gsdali/OCCTSwiftMesh/issues/1) tracks the work. Execute the plan; flag any blockers (especially around OCCTSwift's `Mesh` construction surface) before papering over them. Do not modify vendored meshoptimizer source.

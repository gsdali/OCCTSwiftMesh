# Changelog

All notable changes to OCCTSwiftMesh.

## v0.1.0 — `Mesh.simplified(_:)` via vendored meshoptimizer

Initial release. QEM mesh decimation backed by [meshoptimizer](https://github.com/zeux/meshoptimizer) v1.1 (MIT, vendored under `Sources/OCCTMeshOptimizer/src/meshoptimizer/`).

Requires OCCTSwift v0.156.2 or later (public `Mesh(vertices:normals:indices:)` initializer from [OCCTSwift#94](https://github.com/gsdali/OCCTSwift/issues/94)).

```swift
let result = mesh.simplified(.init(targetTriangleCount: 5_000))
// → SimplifiedMesh(mesh:, beforeTriangleCount:, afterTriangleCount:, hausdorffDistance:)
```

Validation:

- `targetTriangleCount` and `targetReduction` are mutually exclusive; one must be set.
- `targetTriangleCount` must be in `[1, input.triangleCount]`.
- `targetReduction` must be in `[0.0, 1.0]`.
- `maxHausdorffDistance`, when set, must be `>= 0`.
- Empty input meshes are rejected.

Bridge ABI (`Sources/OCCTMeshOptimizer/include/OCCTMeshOptimizer.h`):

- `OCCTMeshSimplify(...)` — runs the QEM pass, compacts orphan vertices via meshoptimizer's fetch remap, reports absolute Hausdorff distance.
- `OCCTMeshSimplifyFreeResult(...)` — releases caller-owned output buffers.
- `OCCTMeshSimplifyScale(...)` — exposes meshoptimizer's bbox-diagonal scale factor for callers that work in relative error units.

Tracking issue: [#1](https://github.com/gsdali/OCCTSwiftMesh/issues/1).

---

## Pre-release scaffold (2026-04-29)

Repository created with package skeleton, build scaffolding, and implementation plan in `docs/INITIAL_IMPLEMENTATION.md`. No public API yet — see [issue #1](https://github.com/gsdali/OCCTSwiftMesh/issues/1).

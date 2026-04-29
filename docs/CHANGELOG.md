# Changelog

All notable changes to OCCTSwiftMesh.

## Unreleased

### v0.1.0 (planned) — `Mesh.simplified(_:)` via vendored meshoptimizer

Initial release. Adds quadric-error-metric (QEM) mesh decimation backed by [meshoptimizer](https://github.com/zeux/meshoptimizer) (BSD-2-Clause, vendored under `Sources/OCCTMeshOptimizer/src/meshoptimizer/`).

API:

```swift
let result = mesh.simplified(.init(targetTriangleCount: 5_000))
// → SimplifiedMesh(mesh:, beforeTriangleCount:, afterTriangleCount:, hausdorffDistance:)
```

Tracking issue: [#1](https://github.com/gsdali/OCCTSwiftMesh/issues/1).

---

## Pre-release scaffold (2026-04-29)

Repository created with package skeleton, build scaffolding, and implementation plan in `docs/INITIAL_IMPLEMENTATION.md`. No public API yet — see [issue #1](https://github.com/gsdali/OCCTSwiftMesh/issues/1).

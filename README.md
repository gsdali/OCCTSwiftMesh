# OCCTSwiftMesh

Mesh-domain algorithms for the [OCCTSwift](https://github.com/gsdali/OCCTSwift) ecosystem. Operates on `OCCTSwift.Mesh` instances; complements the OCCT-side topology kernel rather than extending it.

```
OCCTSwift           — B-Rep solid modelling kernel (wraps OpenCASCADE)
OCCTSwiftMesh       — mesh-domain algorithms (decimation, smoothing, repair, ...)
OCCTSwiftViewport   — Metal viewport for rendering
OCCTSwiftScripts    — script harness + occtkit CLI verbs
```

## Why a separate package

OCCT's open-source distribution provides `BRepMesh_*` for mesh **generation** but no **decimation, simplification, smoothing, hole-filling, remeshing, or other mesh-side post-processing**. OCCT-Components ships a paywalled "Mesh Decimation" module — this package fills the same role with permissive, vendored implementations.

OCCTSwift itself stays focused on its mission as an OCCT wrapper. Mesh algorithms that happen to consume OCCT-produced meshes live here.

## Status

✅ **v0.1.0** ships `Mesh.simplified(_:)` backed by vendored [meshoptimizer](https://github.com/zeux/meshoptimizer) v1.1. Requires OCCTSwift v0.156.2 or later. See [docs/CHANGELOG.md](docs/CHANGELOG.md) and [docs/algorithms/decimation.md](docs/algorithms/decimation.md).

## API

```swift
import OCCTSwift
import OCCTSwiftMesh

let mesh: Mesh = shape.mesh()  // from OCCTSwift
let simplified = mesh.simplified(.init(
    targetTriangleCount: 5_000,
    preserveBoundary: true,
    preserveTopology: true
))

if let result = simplified {
    print("\(result.beforeTriangleCount) → \(result.afterTriangleCount)")
    print("Hausdorff: \(result.hausdorffDistance)")
    let reducedMesh = result.mesh
}
```

## Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/gsdali/OCCTSwiftMesh.git", from: "0.1.0"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "OCCTSwiftMesh", package: "OCCTSwiftMesh"),
        ]
    )
]
```

## License

LGPL-2.1, matching OCCTSwift. Vendored components retain their own permissive licenses (notably meshoptimizer under MIT). See [NOTICE.md](NOTICE.md).

## Roadmap

Beyond initial decimation:

- Subdivision (Catmull-Clark, Loop)
- Laplacian / Taubin smoothing
- Mesh repair (non-manifold cleanup, hole filling)
- Remeshing (uniform / adaptive)
- glTF mesh-export niceties (LOD chains, meshopt-encoded streams)
- GPU-accelerated mesh ops where worthwhile

Community needs drive priority — file an issue if you want one of these (or something else) sooner.

## Related projects

- [OCCTSwift](https://github.com/gsdali/OCCTSwift) — OCCT wrapper, source of `Mesh`
- [OCCTSwiftScripts](https://github.com/gsdali/OCCTSwiftScripts) — script harness; `simplify-mesh` verb consumes this package ([#22](https://github.com/gsdali/OCCTSwiftScripts/issues/22))
- [OCCTMCP](https://github.com/gsdali/OCCTMCP) — MCP server; `simplify_mesh` tool consumes this package via OCCTSwiftScripts ([#6](https://github.com/gsdali/OCCTMCP/issues/6))

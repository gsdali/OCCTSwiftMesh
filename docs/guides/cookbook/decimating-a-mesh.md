---
title: Decimating a Mesh
parent: Cookbook
nav_order: 1
---

# Decimating a Mesh

`Mesh.simplified(_:)` runs a quadric-error-metric (QEM) edge-collapse decimation pass over the
mesh and returns a [`SimplifiedMesh`](../../reference/SimplifiedMesh.md) — the reduced mesh plus
the metadata describing the operation, including the **achieved Hausdorff distance** from input to
output. It is fallible: it returns `nil` when the options are invalid or the input mesh is empty.

## Reduce to a target triangle count

Pass a [`SimplifyOptions`](../../reference/SimplifyOptions.md) (nested as `Mesh.SimplifyOptions`)
with `targetTriangleCount` set:

```swift
import OCCTSwift
import OCCTSwiftMesh

let mesh: Mesh = shape.mesh()                       // a tessellated Shape from OCCTSwift

guard let result = mesh.simplified(.init(targetTriangleCount: 5_000)) else {
    // nil → empty input, or invalid options (neither/both targets set, out of range)
    return
}

print("\(result.beforeTriangleCount) → \(result.afterTriangleCount) triangles")
print("Hausdorff error: \(result.hausdorffDistance)")   // absolute, in input mesh units
let reduced: Mesh = result.mesh
```

`afterTriangleCount` is a **soft** target: the algorithm may return more triangles than requested
when topology preservation or the Hausdorff cap stops it early (a tetrahedron can't go below 4
triangles, for example). Always read `afterTriangleCount` for the actual count and
`hausdorffDistance` to understand the quality.

## Read and cap the Hausdorff error

`hausdorffDistance` is reported on **every** successful call, whether or not you set a cap. To make
deviation the controlling constraint, set `maxHausdorffDistance` (absolute, in input units) —
decimation halts as soon as the measured deviation would exceed it:

```swift
var options = Mesh.SimplifyOptions(targetReduction: 0.9)   // ask for an aggressive 90% cut...
options.maxHausdorffDistance = 0.05                        // ...but never deviate more than 0.05

guard let result = mesh.simplified(options) else { return }

if result.hausdorffDistance >= 0.05 {
    print("Hit the deviation cap at \(result.afterTriangleCount) triangles")
}
```

`maxHausdorffDistance` must be `>= 0`; a negative value makes `simplified(_:)` return `nil`.

## Preserve boundary edges

When decimating an open shell — or a mesh you'll later sew back into a B-Rep — keep the free edges
intact so the boundary doesn't pull inward. `preserveBoundary` defaults to `true`:

```swift
var options = Mesh.SimplifyOptions(targetReduction: 0.5)
options.preserveBoundary = true     // free (boundary) edges are not collapsed
options.preserveTopology = true     // collapses that change genus are rejected (always on today)

guard let result = mesh.simplified(options) else { return }
```

`preserveTopology` is a forward-compatibility flag — the current backend always preserves topology,
so setting it to `false` does not (yet) produce more aggressive decimation. See the
[decimation algorithm notes](../../algorithms/decimation.md) for the full backend semantics,
vendored meshoptimizer pin, and Hausdorff-unit details.

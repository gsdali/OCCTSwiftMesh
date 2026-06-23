---
title: Mesh+Simplify
parent: API Reference
---

# Mesh+Simplify

The decimation entry point. OCCTSwiftMesh extends `OCCTSwift.Mesh` with `simplified(_:)`, a
quadric-error-metric (QEM) edge-collapse decimator backed by the vendored
[meshoptimizer](https://github.com/zeux/meshoptimizer). It takes a
[`SimplifyOptions`](SimplifyOptions.md) and returns a [`SimplifiedMesh`](SimplifiedMesh.md) — the
reduced mesh plus the achieved Hausdorff distance — or `nil` on invalid input. See the
[decimation algorithm notes](../algorithms/decimation.md) for the backend semantics.

## Topics

- [simplified(\_:)](#simplified_)

---

### `simplified(_:)`

Decimate this mesh using a quadric-error-metric edge-collapse algorithm. Orphan vertices left behind
by collapsed edges are compacted, so the output mesh's `vertexCount` is exactly the count of vertices
still referenced by a surviving triangle.

```swift
public func simplified(_ options: Mesh.SimplifyOptions) -> SimplifiedMesh?
```

- **Parameters:**
  - `options` — a [`Mesh.SimplifyOptions`](SimplifyOptions.md) carrying the target count *or*
    reduction ratio (exactly one), plus optional boundary / topology / Hausdorff constraints.
- **Returns:** a [`SimplifiedMesh`](SimplifiedMesh.md) carrying the decimated mesh and the achieved
  Hausdorff distance, or `nil` if the options are invalid (neither or both targets set, a
  `targetTriangleCount` outside `[1, input.triangleCount]`, a `targetReduction` outside `[0, 1]`, or
  a negative `maxHausdorffDistance`) or the input mesh is empty.
- **Example:**
  ```swift
  import OCCTSwift
  import OCCTSwiftMesh

  let mesh: Mesh = shape.mesh()

  var options = Mesh.SimplifyOptions(targetReduction: 0.5)
  options.preserveBoundary = true
  options.maxHausdorffDistance = 0.05

  guard let result = mesh.simplified(options) else { return }
  print("\(result.beforeTriangleCount) → \(result.afterTriangleCount) triangles")
  print("Hausdorff error: \(result.hausdorffDistance)")
  let reduced: Mesh = result.mesh
  ```

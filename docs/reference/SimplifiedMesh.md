---
title: SimplifiedMesh
parent: API Reference
---

# SimplifiedMesh

The successful result of [`Mesh.simplified(_:)`](Mesh-Simplify.md): the decimated mesh together with
the metadata describing the operation. A `Sendable` value type. The `hausdorffDistance` is reported on
every successful call, whether or not a `maxHausdorffDistance` cap was set.

## Topics

- [mesh](#mesh) · [beforeTriangleCount](#beforetrianglecount) · [afterTriangleCount](#aftertrianglecount) · [hausdorffDistance](#hausdorffdistance)

---

### `mesh`

The decimated mesh. Orphan vertices left by collapsed edges are already compacted, so its
`vertexCount` is exactly the count of vertices referenced by a surviving triangle.

```swift
public let mesh: Mesh
```

- **Example:**
  ```swift
  guard let result = mesh.simplified(.init(targetReduction: 0.5)) else { return }
  let reduced: Mesh = result.mesh
  try reduced.writeSTL(to: outputURL)   // OCCTSwift exporter
  ```

---

### `beforeTriangleCount`

Triangle count of the input mesh.

```swift
public let beforeTriangleCount: Int
```

- **Example:**
  ```swift
  print("input had \(result.beforeTriangleCount) triangles")
  ```

---

### `afterTriangleCount`

Triangle count of the output mesh. May **exceed** the requested target if the algorithm could not
reduce further while respecting the `maxHausdorffDistance` cap or topology preservation — treat the
requested target as a soft upper bound.

```swift
public let afterTriangleCount: Int
```

- **Example:**
  ```swift
  if result.afterTriangleCount > 5_000 {
      print("overshoot — couldn't reach 5000")
  }
  ```

---

### `hausdorffDistance`

The achieved Hausdorff distance from input to output mesh, in input units (absolute). Reported
regardless of whether `maxHausdorffDistance` was set — read it to understand the decimation quality.

```swift
public let hausdorffDistance: Double
```

- **Example:**
  ```swift
  print("max surface deviation: \(result.hausdorffDistance) units")
  ```

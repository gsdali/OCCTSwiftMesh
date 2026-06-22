---
title: SimplifyOptions
parent: API Reference
---

# SimplifyOptions

Input parameters for [`Mesh.simplified(_:)`](Mesh-Simplify.md). Declared as a nested type,
`Mesh.SimplifyOptions`, and `Sendable`. **Exactly one** of `targetTriangleCount` or
`targetReduction` must be set — passing both or neither makes `simplified(_:)` return `nil`.

## Topics

- [init(targetTriangleCount:targetReduction:preserveBoundary:preserveTopology:maxHausdorffDistance:)](#inittargettrianglecounttargetreductionpreserveboundarypreservetopologymaxhausdorffdistance)
- [targetTriangleCount](#targettrianglecount) · [targetReduction](#targetreduction) · [preserveBoundary](#preserveboundary) · [preserveTopology](#preservetopology) · [maxHausdorffDistance](#maxhausdorffdistance)

---

### `init(targetTriangleCount:targetReduction:preserveBoundary:preserveTopology:maxHausdorffDistance:)`

Creates a `SimplifyOptions`. Set exactly one of `targetTriangleCount` / `targetReduction`; the
remaining parameters default to boundary- and topology-preserving with no Hausdorff cap.

```swift
public init(
    targetTriangleCount: Int? = nil,
    targetReduction: Double? = nil,
    preserveBoundary: Bool = true,
    preserveTopology: Bool = true,
    maxHausdorffDistance: Double? = nil
)
```

- **Parameters:**
  - `targetTriangleCount` — exact target triangle count; mutually exclusive with `targetReduction`.
  - `targetReduction` — fraction of triangles to remove in `[0, 1]`; mutually exclusive with
    `targetTriangleCount`.
  - `preserveBoundary` — keep free (boundary) edges from collapsing. Default `true`.
  - `preserveTopology` — reject collapses that change genus. Default `true`.
  - `maxHausdorffDistance` — optional deviation cap (absolute, input units, `>= 0`).
- **Example:**
  ```swift
  var options = Mesh.SimplifyOptions(targetReduction: 0.5)
  options.preserveBoundary = true
  options.maxHausdorffDistance = 0.05
  let result = mesh.simplified(options)
  ```

---

### `targetTriangleCount`

Exact target number of triangles in the output mesh. Mutually exclusive with `targetReduction`.
Must be in `[1, input.triangleCount]`.

```swift
public var targetTriangleCount: Int?
```

- **Example:**
  ```swift
  let opts = Mesh.SimplifyOptions(targetTriangleCount: 5_000)
  ```

---

### `targetReduction`

Fraction of input triangles to remove, in `[0.0, 1.0]`. `0.0` = no reduction; `1.0` = decimate as
far as possible. Mutually exclusive with `targetTriangleCount`. The resolved target count is
`round(inputCount × (1 − targetReduction))`, floored at 1.

```swift
public var targetReduction: Double?
```

- **Example:**
  ```swift
  let opts = Mesh.SimplifyOptions(targetReduction: 0.75)   // remove 75%
  ```

---

### `preserveBoundary`

When `true`, edges on the mesh boundary (free edges) are not collapsed — important when decimating an
open shell or a mesh that will be sewn back into a B-Rep.

```swift
public var preserveBoundary: Bool
```

- **Example:**
  ```swift
  var opts = Mesh.SimplifyOptions(targetReduction: 0.5)
  opts.preserveBoundary = true
  ```

---

### `preserveTopology`

Forward-compatibility flag. The current backend **always** preserves topology — collapses that would
change the surface's genus (creating holes, splitting or merging components) are rejected regardless
of this setting. Setting it to `false` does not (yet) produce more aggressive decimation.

```swift
public var preserveTopology: Bool
```

- **Example:**
  ```swift
  var opts = Mesh.SimplifyOptions(targetTriangleCount: 1_000)
  opts.preserveTopology = true   // always honoured today
  ```

---

### `maxHausdorffDistance`

Optional Hausdorff distance cap. When set, decimation halts as soon as the measured deviation from
the input mesh would exceed this value, even if the target count has not been reached. Units match
the input mesh's vertex coordinates (absolute). Must be `>= 0`; a negative value makes
`simplified(_:)` return `nil`.

```swift
public var maxHausdorffDistance: Double?
```

- **Example:**
  ```swift
  var opts = Mesh.SimplifyOptions(targetReduction: 0.9)
  opts.maxHausdorffDistance = 0.05   // never deviate more than 0.05 units
  ```

---
title: Cross-Section Types
parent: API Reference
---

# Cross-Section Types

Planar slicing of a mesh into closed contours — the perimeter step a 3D-printer slicer performs.
`CutPlane` describes the cut; `MeshContour` is one classified closed loop; `MeshCrossSection` is the
whole slice (plane basis + every loop). The entry points are the `Mesh.crossSection(plane:)` and
`Mesh.crossSections(axis:through:spacing:)` extension methods. Pure geometry over
`Mesh.vertices` / `Mesh.indices` (no OCCT kernel calls), so it stays robust on open / unwelded scan
meshes. All three value types are `Sendable`.

## Topics

- [CutPlane](#cutplane) · [CutPlane.init(point:normal:)](#cutplaneinitpointnormal) · [CutPlane.perpendicular(to:offset:)](#cutplaneperpendiculartooffset)
- [MeshContour](#meshcontour) · [points](#points) · [signedArea](#signedarea) · [depth](#depth) · [parent](#parent) · [isHole](#ishole) · [area](#area) · [perimeter](#perimeter) · [bounds](#bounds)
- [MeshCrossSection](#meshcrosssection) · [origin / normal / uAxis / vAxis](#origin--normal--uaxis--vaxis) · [contours](#contours) · [openPaths](#openpaths) · [outerContours](#outercontours) · [worldPoint(\_:)](#worldpoint_)
- [Mesh.crossSection(plane:minLoopArea:weld:)](#meshcrosssectionplaneminloopareaweld) · [Mesh.crossSections(axis:through:spacing:margin:)](#meshcrosssectionsaxisthroughspacingmargin)

---

## CutPlane

An oriented cut plane: a point on the plane and its normal. The normal need not be unit length —
`Mesh.crossSection` normalizes it.

```swift
public struct CutPlane: Sendable {
    public var point: SIMD3<Double>    // a point that lies on the plane
    public var normal: SIMD3<Double>   // the plane normal (any non-zero length)
}
```

---

### `CutPlane.init(point:normal:)`

Creates a cut plane from a point and a (not-necessarily-unit) normal.

```swift
public init(point: SIMD3<Double>, normal: SIMD3<Double>)
```

- **Parameters:**
  - `point` — a point that lies on the plane.
  - `normal` — the plane normal; any non-zero length (normalized on use).
- **Example:**
  ```swift
  let plane = CutPlane(point: SIMD3(0, 0, 5), normal: SIMD3(0, 0, 1))
  ```

---

### `CutPlane.perpendicular(to:offset:)`

A plane perpendicular to `axis`, positioned `offset` along it from the origin.

```swift
public static func perpendicular(to axis: SIMD3<Double>, offset: Double) -> CutPlane
```

- **Parameters:**
  - `axis` — the direction the plane is perpendicular to (normalized internally).
  - `offset` — signed distance along the normalized axis from the origin.
- **Returns:** the `CutPlane`.
- **Example:**
  ```swift
  let z5 = CutPlane.perpendicular(to: SIMD3(0, 0, 1), offset: 5)   // the z = 5 plane
  ```

---

## MeshContour

One closed loop of a cross-section, expressed in the plane's 2D `(u, v)` basis. Loops are implicitly
closed (the last point connects back to the first; the first point is not repeated). `depth` /
`isHole` come from nesting, so they are reliable even on meshes with inconsistent triangle winding.

```swift
public struct MeshContour: Sendable {
    public var points: [SIMD2<Double>]
    public var signedArea: Double
    public var depth: Int
    public var parent: Int?
}
```

---

### `points`

Ordered loop points in the section plane's `(u, v)` coordinates (millimetres). Implicitly closed.

```swift
public var points: [SIMD2<Double>]
```

---

### `signedArea`

Shoelace signed area in plane coordinates (CCW positive). After `crossSection` returns, orientation is
normalized so an even `depth` (solid boundary) is CCW (`> 0`) and an odd `depth` (hole) is CW (`< 0`).

```swift
public var signedArea: Double
```

---

### `depth`

Nesting depth: `0` = outermost solid boundary, `1` = a hole inside it (inner wall / window), `2` = a
solid island inside that hole, etc.

```swift
public var depth: Int
```

---

### `parent`

Index (into the section's `contours`) of the immediately enclosing loop, or `nil` for an outermost
loop.

```swift
public var parent: Int?
```

---

### `isHole`

`true` when this loop bounds empty space inside a solid (odd nesting depth).

```swift
public var isHole: Bool { get }   // depth % 2 == 1
```

- **Example:**
  ```swift
  for c in section.contours where c.isHole {
      print("hole of area \(c.area)")
  }
  ```

---

### `area`

Unsigned enclosed area.

```swift
public var area: Double { get }   // abs(signedArea)
```

---

### `perimeter`

Total perimeter length of the loop (sum of edge lengths, including the implicit closing edge).

```swift
public var perimeter: Double { get }
```

---

### `bounds`

Axis-aligned bounds in plane coordinates: `(min, max)`.

```swift
public var bounds: (min: SIMD2<Double>, max: SIMD2<Double>) { get }
```

---

## MeshCrossSection

A planar cross-section of a mesh: the plane basis plus every closed loop the plane cuts. Map 2D loop
points back to 3D with `worldPoint(_:)`.

```swift
public struct MeshCrossSection: Sendable {
    public var origin: SIMD3<Double>
    public var normal: SIMD3<Double>
    public var uAxis: SIMD3<Double>
    public var vAxis: SIMD3<Double>
    public var contours: [MeshContour]
    public var openPaths: [[SIMD2<Double>]]
}
```

---

### `origin` / `normal` / `uAxis` / `vAxis`

The plane basis. `origin` is the `(u, v) = (0, 0)` point in world space; `normal` is the unit plane
normal; `uAxis` and `vAxis` are the unit in-plane basis vectors (`vAxis = normal × uAxis`).

```swift
public var origin: SIMD3<Double>
public var normal: SIMD3<Double>
public var uAxis: SIMD3<Double>
public var vAxis: SIMD3<Double>
```

---

### `contours`

The closed loops cut by the plane, each classified by nesting depth.

```swift
public var contours: [MeshContour]
```

---

### `openPaths`

Open polylines (in `(u, v)` coordinates) produced where the plane exits the mesh through a boundary
edge — e.g. cutting across an open end or a window rim. Empty for a clean section between features.

```swift
public var openPaths: [[SIMD2<Double>]]
```

---

### `outerContours`

The outermost loops (nesting depth `0`) — the solid's outer boundary.

```swift
public var outerContours: [MeshContour] { get }
```

- **Example:**
  ```swift
  print("\(section.outerContours.count) outer wall(s)")
  ```

---

### `worldPoint(_:)`

Map a plane `(u, v)` coordinate back to a world-space point.

```swift
public func worldPoint(_ uv: SIMD2<Double>) -> SIMD3<Double>
```

- **Parameters:**
  - `uv` — a point in the plane's `(u, v)` basis (e.g. an element of a contour's `points`).
- **Returns:** the corresponding world-space `SIMD3<Double>`.
- **Example:**
  ```swift
  guard let loop = section.contours.first else { return }
  let worldRing = loop.points.map { section.worldPoint($0) }
  ```

---

## Mesh.crossSection(plane:minLoopArea:weld:)

Slice the mesh with a plane and return the closed contours where the plane cuts the surface — a
3D-printer slicer's perimeter step. Intersection points are welded by quantized world position, so
the two triangles sharing an edge chain without tolerance fuzz; inner walls and pockets come back as
separate loops, classified by nesting.

```swift
func crossSection(plane: CutPlane, minLoopArea: Double = 0, weld: Double = 0) -> MeshCrossSection?
```

- **Parameters:**
  - `plane` — the cut plane (normal need not be unit length).
  - `minLoopArea` — loops with unsigned area below this are discarded as slivers (default `0`, keep
    everything).
  - `weld` — spatial tolerance for welding coincident intersection points (handles unwelded STL). `0`
    (default) auto-derives `1e-6 ×` the mesh's bounding-box diagonal.
- **Returns:** the [`MeshCrossSection`](#meshcrosssection), or `nil` if the plane misses the mesh
  entirely.
- **Example:**
  ```swift
  import OCCTSwift
  import OCCTSwiftMesh

  guard let section = mesh.crossSection(
      plane: CutPlane(point: SIMD3(0, 0, 5), normal: SIMD3(0, 0, 1)),
      minLoopArea: 0.01
  ) else { return }

  for c in section.contours {
      print("depth \(c.depth)\(c.isHole ? " (hole)" : ""): area \(c.area)")
  }
  ```

---

## Mesh.crossSections(axis:through:spacing:margin:)

A stack of evenly-spaced cross-sections along an axis — a slicer's layer stack. Sections that miss the
mesh are skipped.

```swift
func crossSections(axis: SIMD3<Double>, through point: SIMD3<Double>,
                   spacing: Double, margin: Double? = nil) -> [MeshCrossSection]
```

- **Parameters:**
  - `axis` — slicing direction (normalized internally).
  - `point` — a point the axis passes through (the stack is measured from here).
  - `spacing` — distance between successive section planes. Must be `> 0` (otherwise returns `[]`).
  - `margin` — inset from each end of the mesh's extent along the axis, so the first/last slice
    doesn't sit exactly on an end cap (default `spacing / 2`).
- **Returns:** an array of [`MeshCrossSection`](#meshcrosssection), one per plane that hit the mesh.
- **Example:**
  ```swift
  let layers = mesh.crossSections(
      axis: SIMD3(0, 0, 1),
      through: SIMD3(0, 0, 0),
      spacing: 0.2            // 0.2 mm layers
  )
  print("\(layers.count) layers")
  ```

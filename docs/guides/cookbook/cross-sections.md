---
title: Cross-Sections & Contours
parent: Cookbook
nav_order: 3
---

# Cross-Sections & Contours

`Mesh.crossSection(plane:)` intersects a mesh with a plane and recovers the **closed contours**
where the plane cuts the surface — the perimeter step a 3D-printer slicer performs. It's pure
geometry over `Mesh.vertices` / `Mesh.indices` (no OCCT kernel calls), so it works directly on the
**open / unwelded** meshes that raw STL and scan bodies actually are, where sewing to a B-Rep first
would fail. The result is a [`MeshCrossSection`](../../reference/CrossSection.md).

## Slice with a plane

Build a [`CutPlane`](../../reference/CrossSection.md#cutplane) from a point and a normal (the normal
need not be unit length — it's normalized internally). The call returns `nil` if the plane misses the
mesh entirely:

```swift
import OCCTSwift
import OCCTSwiftMesh

guard let section = mesh.crossSection(
    plane: CutPlane(point: SIMD3(0, 0, 5), normal: SIMD3(0, 0, 1))
) else {
    return   // plane missed the mesh
}

for c in section.contours {
    let kind = c.isHole ? "hole" : "solid boundary"
    print("depth \(c.depth) \(kind): \(c.points.count) pts, area \(c.area), perimeter \(c.perimeter)")
}
```

There's a convenience constructor for the common axis-aligned case:

```swift
let plane = CutPlane.perpendicular(to: SIMD3(0, 0, 1), offset: 5)   // z = 5 plane
let section = mesh.crossSection(plane: plane)
```

## Outer walls vs. holes come from nesting

Each [`MeshContour`](../../reference/CrossSection.md#meshcontour) is classified by **nesting depth**,
not by triangle winding — so it's reliable even on meshes with inconsistent orientation. `depth == 0`
is an outermost solid boundary; `depth == 1` is a hole inside it (an inner wall or a pocket); deeper
even/odd depths alternate solid/hole. `isHole` is just `depth % 2 == 1`, and orientation is
normalized so solids are CCW (`signedArea > 0`) and holes CW.

For a thin-walled tube the outer and inner walls come back as **two separate, nested loops**, so the
wall thickness is simply their offset:

```swift
// Outermost loops only — the solid's outer boundary
for outer in section.contours.filter({ $0.depth == 0 }) {
    print("outer wall: area \(outer.area)")
}
// equivalently:
let outers = section.outerContours
```

`MeshContour` also exposes `bounds` (axis-aligned `(min, max)` in plane coordinates) and `parent`
(the index of the immediately enclosing loop, or `nil`).

## Map contour points back to 3D

Contour points are 2D `(u, v)` coordinates in the plane's basis. Lift them back to world space with
`worldPoint(_:)`:

```swift
if let loop = section.contours.first {
    let worldRing: [SIMD3<Double>] = loop.points.map { section.worldPoint($0) }
    // worldRing now traces the loop in 3D, useful for re-lofting or display
}
```

Where the plane exits the mesh through a boundary edge (cutting across an open end or a window rim),
those segments come back as **open polylines** in `section.openPaths` rather than closed contours.

## A whole slicer layer stack

`Mesh.crossSections(axis:through:spacing:)` returns a stack of evenly-spaced sections along an axis —
a slicer's layer stack. Sections that miss the mesh are skipped:

```swift
let layers = mesh.crossSections(
    axis: SIMD3(0, 0, 1),
    through: SIMD3(0, 0, 0),
    spacing: 0.2                 // 0.2 mm layers
)

for (i, layer) in layers.enumerated() {
    let outerCount = layer.outerContours.count
    print("layer \(i): \(layer.contours.count) contours (\(outerCount) outer)")
}
```

An optional `margin:` insets the first/last slice from each end of the mesh's extent (it defaults to
`spacing / 2`, so the first and last layers don't sit exactly on an end cap).

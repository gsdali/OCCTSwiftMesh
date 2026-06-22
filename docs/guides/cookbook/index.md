---
title: Cookbook
nav_order: 2
has_children: true
---

# OCCTSwiftMesh Cookbook

Task-oriented, **example-rich** guides for the OCCTSwiftMesh API — one page per task, each a
short bit of prose followed by runnable Swift. Every example uses the real shipped API:
`import OCCTSwiftMesh` (which re-exports `OCCTSwift`'s `Mesh`), and the fallible entry points
(`simplified(_:)` returns an optional, `crossSection(plane:)` returns an optional) are unwrapped
with `guard` / `if let` rather than force-unwrapped.

## Conventions

- **Every example is runnable Swift.** Get a `Mesh` from OCCTSwift (`shape.mesh()`) or build one
  from raw arrays (`Mesh(vertices:indices:)`); the OCCTSwiftMesh entry points are extension methods
  on that `Mesh`.
- **Units are the input mesh's vertex units.** Hausdorff distances, cross-section areas, and
  perimeters all come back in whatever units the input vertices are in (millimetres, typically).
- **Algorithm deep dives live in [`algorithms/`](../../algorithms/decimation.md).** These recipes
  show *usage*; the QEM backend, vendored meshoptimizer pin, and Hausdorff-unit semantics are
  documented there.

## Recipes

- [Decimating a Mesh](decimating-a-mesh.md) — `simplified(_:)` with `SimplifyOptions`, reading
  the achieved Hausdorff error, capping deviation, and preserving boundary edges.
- [Target Count vs. Reduction Ratio](target-count-vs-ratio.md) — the two mutually-exclusive
  targets (`targetTriangleCount` vs. `targetReduction`), overshoot, and when each is the right one.
- [Cross-Sections & Contours](cross-sections.md) — slice a mesh with a `CutPlane`, read the nested
  closed `MeshContour`s, distinguish outer walls from holes, and build a whole slicer layer stack.

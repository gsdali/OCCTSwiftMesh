---
title: API Reference
nav_order: 3
has_children: true
---

# OCCTSwiftMesh API Reference

A **detailed, per-type function reference** for the OCCTSwiftMesh Swift API. One page per public
type, every public symbol documented: signature, behaviour, parameters, return value, and a runnable
example.

This complements the other docs — it's the *exhaustive* surface, vs:
- [`guides/cookbook/`](../guides/cookbook/) — *task-oriented* example pages.
- [`algorithms/decimation.md`](../algorithms/decimation.md) — the QEM backend deep dive.

OCCTSwiftMesh adds its public surface as **extensions on `OCCTSwift.Mesh`** (the triangle-soup value
type, re-exported via `import OCCTSwiftMesh`) plus the value types each algorithm returns. There is no
free-standing API beyond the `OCCTSwiftMesh` namespace marker.

## Types

- **[OCCTSwiftMesh](OCCTSwiftMesh.md)** — the module namespace marker (`version` constant).
- **[Mesh+Simplify](Mesh-Simplify.md)** — the `Mesh.simplified(_:)` decimation entry point.
- **[SimplifyOptions](SimplifyOptions.md)** — `Mesh.SimplifyOptions`, the decimation inputs.
- **[SimplifiedMesh](SimplifiedMesh.md)** — the decimation result (mesh + before/after counts +
  Hausdorff distance).
- **[Cross-Section Types](CrossSection.md)** — `CutPlane`, `MeshContour`, `MeshCrossSection`, and the
  `Mesh.crossSection(plane:)` / `Mesh.crossSections(axis:through:spacing:)` slicing entry points.

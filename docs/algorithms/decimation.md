# Decimation (`Mesh.simplified(_:)`)

Quadric-error-metric (QEM) edge-collapse mesh decimation, backed by [meshoptimizer](https://github.com/zeux/meshoptimizer).

## Algorithm choice

Meshoptimizer's `meshopt_simplify` is a production QEM decimator with these properties relevant to OCCTSwiftMesh consumers:

- **Permissively licensed (MIT)** — compatible with our LGPL-2.1 licensing, vendored verbatim.
- **No dependencies** — pure C++17, builds on every platform OCCTSwift targets.
- **Boundary-aware** — `meshopt_SimplifyLockBorder` flag preserves free edges, which matters when decimating an open shell or a mesh that will be sewn back into a B-Rep.
- **Topology-preserving by default** — collapses that would change the surface's genus (creating holes, splitting components, merging components) are rejected. This is what we want for v0.1; consumers who want sloppy decimation can drop down to `meshopt_simplifySloppy` once we expose it.
- **Reports achieved error** — the algorithm returns the maximum quadric error it had to accept, which we expose as `hausdorffDistance` in the same units as the input vertex coordinates.

Alternatives we did not pick:

- **OCCT-Components Mesh Decimation** — paywalled. The whole reason this package exists.
- **CGAL Surface_mesh_simplification** — GPL-licensed; would force OCCTSwiftMesh to GPL.
- **OpenMesh / libigl decimation** — heavier dependency footprint, no real quality advantage for our use case.

## Edge cases & semantics

### Vertex compaction

`meshopt_simplify` writes a reduced index buffer but leaves the vertex array as-is — many vertices become orphans after edges collapse. Returning the un-compacted buffer would technically work but bloat memory and break any downstream code that iterates `vertices.count` expecting only referenced vertices.

The bridge runs `meshopt_optimizeVertexFetchRemap` followed by `meshopt_remapVertexBuffer` + `meshopt_remapIndexBuffer` to compact. Output `vertices.count` is exactly the count of vertices referenced by at least one surviving triangle.

### Hausdorff units

Meshoptimizer internally tracks quadric error in *relative* units (fraction of the bounding-box diagonal). The `meshopt_SimplifyErrorAbsolute` flag flips both the input `target_error` and the output `result_error` into absolute coordinate units. The bridge always passes this flag, so:

- `OCCTMeshSimplify`'s `targetError` parameter is **absolute**, in input mesh units.
- `OCCTMeshSimplifyResult.hausdorffDistance` is **absolute**, in input mesh units.
- `OCCTMeshSimplifyScale` is exposed for callers who want to convert their own relative tolerances or compare against meshoptimizer's relative-error API directly. The OCCTSwift wrapper does not currently use it.

### `preserveTopology = false`

The `Mesh.SimplifyOptions.preserveTopology` flag exists in the public API for forward compatibility with `meshopt_simplifySloppy` (which we may expose as a separate code path in a future release). In v0.1 the bridge always preserves topology — this is meshoptimizer's default behavior with `meshopt_simplify`. Setting `preserveTopology = false` does **not** currently produce more aggressive decimation. The wrapper's docstring documents this.

### Empty / degenerate input

The Swift wrapper rejects empty meshes (`triangleCount == 0` or `vertexCount == 0`) at validation, returning `nil` before calling the bridge. The bridge defensively checks `vertexCount >= 3` and `indexCount >= 3` and `indexCount % 3 == 0` again, returning `false` on any violation.

### Target overshoot

`meshopt_simplify` may return a triangle count higher than the requested target when:

- Topology preservation prevents further collapses (e.g. a tetrahedron can't be reduced below 4 triangles).
- The Hausdorff cap is reached before the target count.

`SimplifiedMesh.afterTriangleCount` reports the actual count. Callers checking against a target should treat it as a soft upper bound and use `hausdorffDistance` to understand quality.

## Performance characteristics

Linear in input triangle count for typical meshes. Meshoptimizer's QEM implementation is heavily optimized; expect ~1M triangles/sec on a single core. The bridge wraps three additional buffer copies (one for the simplified indices, one each for the compacted vertex / index outputs), which dominates allocation cost but is negligible compared to the algorithm itself.

The bridge does not parallelize internally. Callers decimating many meshes can do so concurrently — `OCCTMeshSimplify` is reentrant and operates on caller-owned input buffers.

## Vendored version pin

Currently pinned to **meshoptimizer v1.1**. See [`NOTICE.md`](../../NOTICE.md) for the vendored version and [`docs/VENDORING.md`](../VENDORING.md) for the re-vendoring procedure.

The bridge uses these meshoptimizer entry points:

- `meshopt_simplify` (line 490 of `meshoptimizer.h` v1.1)
- `meshopt_simplifyScale` (line 588)
- `meshopt_optimizeVertexFetchRemap` (line 239)
- `meshopt_remapVertexBuffer` (line 96)
- `meshopt_remapIndexBuffer` (line 104)

And these flags:

- `meshopt_SimplifyLockBorder` (preserves boundary edges)
- `meshopt_SimplifyErrorAbsolute` (treats target/result error as absolute)

If a future re-vendor renames or removes any of these, the bridge needs corresponding updates. The vendored `meshoptimizer.h` is the source of truth.

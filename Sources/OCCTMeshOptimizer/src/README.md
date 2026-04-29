# OCCTMeshOptimizer source layout

This directory holds:

- `OCCTMeshOptimizerBridge.cpp` — the bridge implementation between the C ABI declared in `../include/OCCTMeshOptimizer.h` and the vendored meshoptimizer library
- `meshoptimizer/` — vendored upstream source from https://github.com/zeux/meshoptimizer (MIT, copied verbatim)

Vendored sources are **never modified in-tree.** Bug fixes go upstream first; we re-vendor against the next tagged release.

Vendored version is recorded in [`../../../NOTICE.md`](../../../NOTICE.md).

See [`../../../docs/VENDORING.md`](../../../docs/VENDORING.md) for the re-vendoring procedure.

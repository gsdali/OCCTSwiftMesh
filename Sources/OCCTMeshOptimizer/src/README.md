# OCCTMeshOptimizer source layout

This directory will hold:

- `OCCTMeshOptimizerBridge.cpp` — the bridge implementation between the C ABI declared in `../include/OCCTMeshOptimizer.h` and the vendored meshoptimizer library
- `meshoptimizer/` — vendored upstream source from https://github.com/zeux/meshoptimizer (BSD-2-Clause, copied verbatim)

Vendored sources are **never modified in-tree.** Bug fixes go upstream first; we re-vendor against the next tagged release.

Vendored version is recorded in [`../../../NOTICE.md`](../../../NOTICE.md).

See [`docs/VENDORING.md`](../../../docs/VENDORING.md) (to be written when first vendored) for the re-vendoring procedure.

# Vendoring meshoptimizer

This package vendors [meshoptimizer](https://github.com/zeux/meshoptimizer) directly into `Sources/OCCTMeshOptimizer/src/meshoptimizer/`. Vendoring keeps OCCTSwiftMesh self-contained — `swift build` produces a fully linked library without any system dependencies — and pins the algorithm version exactly.

The currently vendored version is recorded in [`NOTICE.md`](../NOTICE.md).

## Don't modify vendored sources

Bug fixes go upstream first. If you need a change in meshoptimizer:

1. Open a PR against [zeux/meshoptimizer](https://github.com/zeux/meshoptimizer).
2. Wait for it to land and ship in a tagged release.
3. Re-vendor against that release (procedure below).

This keeps OCCTSwiftMesh permissively-licensed and avoids divergence from upstream.

## Re-vendoring procedure

Run from a clean working tree.

### 1. Identify the target version

```bash
gh release list --repo zeux/meshoptimizer --limit 5
```

Pick the latest stable tag (avoid pre-releases).

### 2. Download and extract

```bash
TAG=v1.2  # adjust
curl -sL "https://github.com/zeux/meshoptimizer/archive/refs/tags/${TAG}.tar.gz" -o /tmp/meshoptimizer-${TAG}.tar.gz
tar xzf /tmp/meshoptimizer-${TAG}.tar.gz -C /tmp/
```

### 3. Replace the vendor tree

```bash
cd "$(git rev-parse --show-toplevel)"
rm -rf Sources/OCCTMeshOptimizer/src/meshoptimizer
mkdir -p Sources/OCCTMeshOptimizer/src/meshoptimizer
cp /tmp/meshoptimizer-${TAG#v}/src/*.cpp \
   /tmp/meshoptimizer-${TAG#v}/src/*.h \
   /tmp/meshoptimizer-${TAG#v}/LICENSE.md \
   Sources/OCCTMeshOptimizer/src/meshoptimizer/
```

The trailing `LICENSE.md` lives at the repo root upstream — make sure it lands under `meshoptimizer/` in the vendor tree.

### 4. Update metadata

- Bump the `Vendored version` and `last vendored` date in [`NOTICE.md`](../NOTICE.md).
- If the upstream copyright notice has changed, refresh the verbatim block in `NOTICE.md` against `Sources/OCCTMeshOptimizer/src/meshoptimizer/LICENSE.md`.

### 5. Verify the bridge still compiles

```bash
swift build
swift test
```

If meshoptimizer changed any of `meshopt_simplify`, `meshopt_simplifyScale`, `meshopt_optimizeVertexFetchRemap`, `meshopt_remapVertexBuffer`, or `meshopt_remapIndexBuffer` signatures or flag values (notably `meshopt_SimplifyLockBorder`, `meshopt_SimplifyErrorAbsolute`), update `Sources/OCCTMeshOptimizer/src/OCCTMeshOptimizerBridge.cpp` to match. The vendored upstream `meshoptimizer.h` is the source of truth.

### 6. Run tests against the new version

The full Swift Testing suite must pass before re-vendoring lands. Pay particular attention to:

- `targetReduction` produces a count below the input
- `hausdorffDistance` stays finite and non-negative
- Output indices stay within the compacted vertex range

These exercise the bridge end-to-end against the new vendored source.

### 7. Commit and CHANGELOG

Land the re-vendor as a single commit:

```bash
git add Sources/OCCTMeshOptimizer/src/meshoptimizer NOTICE.md
git commit -m "Vendor meshoptimizer ${TAG}"
```

Add an entry to [`docs/CHANGELOG.md`](CHANGELOG.md) under the next release noting the version bump. If the bump fixes a known issue or unblocks a feature, link the relevant issue.

## When NOT to re-vendor

- During the freeze window before a release tag — re-vendor at the start of a release cycle, not the end.
- If the new upstream version drops or renames any function we use without a deprecation period — file an issue first and decide whether to pin the older version or update the bridge.
- For prerelease/RC tags from upstream — wait for the stable.

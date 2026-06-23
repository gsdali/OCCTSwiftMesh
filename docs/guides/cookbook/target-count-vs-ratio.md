---
title: Target Count vs. Reduction Ratio
parent: Cookbook
nav_order: 2
---

# Target Count vs. Reduction Ratio

[`SimplifyOptions`](../../reference/SimplifyOptions.md) offers two ways to say *how much* to
decimate, and they are **mutually exclusive**: exactly one of `targetTriangleCount` or
`targetReduction` must be set. Passing both — or neither — makes `simplified(_:)` return `nil`.

## `targetTriangleCount` — an absolute count

Use this when you have a concrete budget (a LOD tier, a renderer's per-draw triangle ceiling). The
count must be in `[1, input.triangleCount]`; outside that range the call returns `nil`.

```swift
import OCCTSwift
import OCCTSwiftMesh

guard let result = mesh.simplified(.init(targetTriangleCount: 2_000)) else { return }
print("Reduced to \(result.afterTriangleCount) triangles")
```

## `targetReduction` — a fraction to remove

Use this when you want a proportional cut regardless of the input size. It is the **fraction of
triangles to remove**, in `[0.0, 1.0]`: `0.0` removes nothing, `1.0` decimates as far as the backend
can. Internally the target count is `round(inputCount × (1 − ratio))`, floored at 1.

```swift
// Remove 75% of the triangles (keep ~25%)
guard let result = mesh.simplified(.init(targetReduction: 0.75)) else { return }

let keptFraction = Double(result.afterTriangleCount) / Double(result.beforeTriangleCount)
print(String(format: "Kept %.0f%%", keptFraction * 100))
```

## Don't set both

The two targets cannot be combined. This returns `nil`:

```swift
// ✗ both set → nil
let bad = mesh.simplified(.init(targetTriangleCount: 2_000, targetReduction: 0.5))
assert(bad == nil)

// ✗ neither set → nil
let alsoBad = mesh.simplified(.init())
assert(alsoBad == nil)
```

## Overshoot is normal

Neither target is hard. `afterTriangleCount` can exceed the requested count when topology
preservation or a `maxHausdorffDistance` cap stops the collapse early. Treat the requested target as
a soft upper bound and check the actual result:

```swift
guard let result = mesh.simplified(.init(targetTriangleCount: 100)) else { return }
if result.afterTriangleCount > 100 {
    print("Stopped at \(result.afterTriangleCount) — couldn't reduce further")
    print("Deviation so far: \(result.hausdorffDistance)")
}
```

See [Decimating a Mesh](decimating-a-mesh.md) for the boundary / Hausdorff options and the
[algorithm notes](../../algorithms/decimation.md) for why overshoot happens.

---
title: OCCTSwiftMesh
parent: API Reference
---

# OCCTSwiftMesh

The module namespace marker. OCCTSwiftMesh's actual public surface lives on **extensions of
`OCCTSwift.Mesh`** (`simplified(_:)`, `crossSection(plane:)`, `crossSections(...)`) and the value
types declared alongside each algorithm. This enum exists only to give Xcode something concrete to
attach the module's documentation to, and to carry the package version.

## Topics

- [version](#version)

---

### `version`

The package version string, bumped on each tagged release.

```swift
public static let version: String
```

- **Returns:** the current version string (e.g. `"1.1.0"`).
- **Example:**
  ```swift
  import OCCTSwiftMesh

  print("OCCTSwiftMesh \(OCCTSwiftMesh.version)")
  ```

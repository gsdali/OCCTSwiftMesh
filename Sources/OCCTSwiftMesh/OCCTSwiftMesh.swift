// OCCTSwiftMesh — mesh-domain algorithms for the OCCTSwift ecosystem.
//
// v0.1.0 ships Mesh.simplified(_:) via vendored meshoptimizer.
// Implementation pending — see docs/INITIAL_IMPLEMENTATION.md and issue #1.

import Foundation
import OCCTSwift
import OCCTMeshOptimizer

/// Namespace marker for the OCCTSwiftMesh module. The public surface lives
/// on extensions of `OCCTSwift.Mesh` and the value types declared alongside
/// each algorithm — this enum exists only to give Xcode something concrete
/// to attach the module's documentation to.
public enum OCCTSwiftMesh {
    /// Package version. Bump on each tagged release.
    public static let version = "0.0.0-pre-alpha"
}

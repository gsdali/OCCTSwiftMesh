// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "OCCTSwiftMesh",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "OCCTSwiftMesh",
            targets: ["OCCTSwiftMesh"]
        ),
    ],
    dependencies: [
        // Pinned to v0.156.0 — first release that exposes Mesh vertex/index getters
        // we depend on. Bump when consuming new OCCTSwift surface.
        .package(url: "https://github.com/gsdali/OCCTSwift.git", from: "0.156.0"),
    ],
    targets: [
        // Public Swift API: Mesh.simplified(_:) and friends.
        .target(
            name: "OCCTSwiftMesh",
            dependencies: [
                .product(name: "OCCTSwift", package: "OCCTSwift"),
                "OCCTMeshOptimizer",
            ],
            path: "Sources/OCCTSwiftMesh",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),

        // C++ bridge target that vendors meshoptimizer (BSD-2-Clause).
        // All of meshoptimizer's .cpp files compile here; the wrapper
        // exposes a small C ABI to the Swift layer.
        .target(
            name: "OCCTMeshOptimizer",
            path: "Sources/OCCTMeshOptimizer",
            sources: ["src"],
            publicHeadersPath: "include",
            cxxSettings: [
                .define("MESHOPTIMIZER_NO_EXPERIMENTAL", to: "0")
            ],
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        ),

        // Tests
        .testTarget(
            name: "OCCTSwiftMeshTests",
            dependencies: ["OCCTSwiftMesh"],
            path: "Tests/OCCTSwiftMeshTests"
        ),
    ],
    cxxLanguageStandard: .cxx17
)

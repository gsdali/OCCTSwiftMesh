import Testing
@testable import OCCTSwiftMesh

@Suite("OCCTSwiftMesh — package scaffold")
struct PackageScaffoldTests {
    @Test("Module loads and exposes its version sentinel")
    func versionSentinel() {
        // v0.1.0 will overwrite this and add real algorithm tests.
        #expect(OCCTSwiftMesh.version.contains("pre-alpha"))
    }
}

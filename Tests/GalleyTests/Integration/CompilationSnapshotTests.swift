import XCTest
@testable import GalleyLib

class CompilationSnapshotTests: XCTestCase {
    var service: CompilerService!

    override func setUpWithError() throws {
        try XCTSkipIf(!Self.isTypstInstalled(), "typst binary not found — skipping snapshot tests")
        service = try CompilerService()
    }

    func testCompileSimpleText() async throws {
        let pdf = try await service.compileTypst("Hello, *world*!")
        XCTAssertFalse(pdf.isEmpty)
        XCTAssertEqual(pdf.prefix(4), Data([0x25, 0x50, 0x44, 0x46]), "Output must start with %PDF magic bytes")
    }

    func testCompileWithMarkup() async throws {
        let code = """
        = My Document

        #let name = "World"
        Hello, #name!
        """
        let pdf = try await service.compileTypst(code)
        XCTAssertFalse(pdf.isEmpty)
        XCTAssertEqual(pdf.prefix(4), Data([0x25, 0x50, 0x44, 0x46]))
    }

    func testInvalidTypstThrows() async throws {
        do {
            _ = try await service.compileTypst("#unknownfn()")
            XCTFail("Expected compilation to throw for invalid Typst")
        } catch let error as CompilerService.CompilerError {
            if case .compilationFailed = error {
                // expected
            } else {
                XCTFail("Expected compilationFailed, got \(error)")
            }
        }
    }

    private static func isTypstInstalled() -> Bool {
        let paths = ["/opt/homebrew/bin/typst", "/usr/local/bin/typst", "/usr/bin/typst"]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }
}

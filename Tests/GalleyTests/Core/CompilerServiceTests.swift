import XCTest
@testable import GalleyLib

class CompilerServiceTests: XCTestCase {
    func testMockCompilerReturnsData() async throws {
        let mock = MockCompiler()
        let testPDF = Data([0x25, 0x50, 0x44, 0x46])
        mock.returnValue = testPDF

        let result = try await mock.compileTypst("#text(\"hello\")")

        XCTAssertEqual(result, testPDF)
    }

    func testMockCompilerThrowsError() async throws {
        let mock = MockCompiler()
        let testError = CompilationError(
            message: "Unknown function: foo",
            line: 1,
            column: 1
        )
        mock.shouldThrow = CompilerService.CompilerError.compilationFailed(testError)

        do {
            _ = try await mock.compileTypst("#foo()")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testMockCompilerResetsState() async throws {
        let mock = MockCompiler()

        mock.returnValue = Data([0x01])
        let result1 = try await mock.compileTypst("test1")
        XCTAssertEqual(result1.count, 1)

        mock.returnValue = Data([0x02, 0x03])
        let result2 = try await mock.compileTypst("test2")
        XCTAssertEqual(result2.count, 2)
    }
}

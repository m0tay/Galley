import XCTest
import Combine
@testable import GalleyLib

class EditorStateTests: XCTestCase {
    var state: EditorState!
    var mockCompiler: MockCompiler!

    override func setUp() {
        super.setUp()
        mockCompiler = MockCompiler()
        state = EditorState(compiler: mockCompiler)
    }

    func testSuccessfulCompilationUpdatesPDFData() async throws {
        let pdfMagic = Data([0x25, 0x50, 0x44, 0x46]) // %PDF
        mockCompiler.returnValue = pdfMagic

        state.editorText = "Hello, *world*!"

        try await Task.sleep(nanoseconds: 700_000_000)

        XCTAssertEqual(state.pdfData, pdfMagic)
        XCTAssertNil(state.compilationError)
        XCTAssertFalse(state.isCompiling)
    }

    func testCompilationErrorUpdatesErrorState() async throws {
        let testError = CompilationError(message: "unknown variable: x", line: 1, column: 5)
        mockCompiler.shouldThrow = CompilerService.CompilerError.compilationFailed(testError)

        state.editorText = "#badcode()"

        try await Task.sleep(nanoseconds: 700_000_000)

        XCTAssertNotNil(state.compilationError)
        XCTAssertEqual(state.compilationError?.message, "unknown variable: x")
        XCTAssertNil(state.pdfData)
        XCTAssertFalse(state.isCompiling)
    }

    func testEmptyTextSkipsCompilation() async throws {
        var callCount = 0
        mockCompiler.onCompile = { _ in callCount += 1 }

        state.editorText = ""

        try await Task.sleep(nanoseconds: 700_000_000)

        XCTAssertEqual(callCount, 0, "Empty text should not trigger compilation")
        XCTAssertNil(state.pdfData)
        XCTAssertNil(state.compilationError)
    }

    func testResetContentClearsState() {
        state.pdfData = Data([0x01])
        state.compilationError = CompilationError(message: "error")

        state.resetContent()

        XCTAssertNil(state.pdfData)
        XCTAssertNil(state.compilationError)
        XCTAssertEqual(state.editorText, "")
    }
}

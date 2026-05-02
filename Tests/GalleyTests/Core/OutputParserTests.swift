import XCTest
@testable import GalleyLib

class OutputParserTests: XCTestCase {
    let parser = OutputParser()

    func testParsesSimpleError() throws {
        let stderr = """
        error: function not found: `foo`
          ┌─ input.typ:5:2
          │
        5 │ #foo()
          │  ^^^ function not found
        """

        let errors = parser.parse(stderr)

        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0].message, "function not found: `foo`")
        XCTAssertEqual(errors[0].line, 5)
        XCTAssertEqual(errors[0].column, 2)
    }

    func testParsesMultipleErrors() throws {
        let stderr = """
        error: unknown variable: x
          ┌─ input.typ:1:1
        error: unknown variable: y
          ┌─ input.typ:2:1
        """

        let errors = parser.parse(stderr)

        XCTAssertEqual(errors.count, 2)
        XCTAssertEqual(errors[0].message, "unknown variable: x")
        XCTAssertEqual(errors[0].line, 1)
        XCTAssertEqual(errors[1].message, "unknown variable: y")
        XCTAssertEqual(errors[1].line, 2)
    }

    func testHandlesEmptyError() throws {
        let stderr = ""
        let errors = parser.parse(stderr)
        XCTAssertEqual(errors.count, 0)
    }

    func testParsesErrorWithContext() throws {
        let stderr = """
        error: expected identifier
          ┌─ input.typ:3:10
          │
        3 │ #let 42 = x
          │          ^ expected identifier
        """

        let errors = parser.parse(stderr)

        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0].message, "expected identifier")
        XCTAssertEqual(errors[0].line, 3)
        XCTAssertEqual(errors[0].column, 10)
    }

    func testIgnoresWarningsAndOnlyParsesErrors() throws {
        let stderr = """
        warning: unused variable
        error: type mismatch
          ┌─ input.typ:2:1
        """

        let errors = parser.parse(stderr)

        XCTAssertEqual(errors.count, 1)
        XCTAssert(errors[0].message.contains("type mismatch"))
    }
}

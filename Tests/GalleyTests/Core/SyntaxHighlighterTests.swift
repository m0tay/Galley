import XCTest
@testable import GalleyLib

class SyntaxHighlighterTests: XCTestCase {
    let highlighter = SyntaxHighlighter()

    func testTokenizesKeyword() {
        let tokens = highlighter.tokenize("#let x = 5")
        let keywords = tokens.filter { $0.type == .keyword }
        XCTAssertEqual(keywords.count, 1)
        XCTAssertEqual(keywords[0].value, "#let")
    }

    func testTokenizesBuiltinFunction() {
        let tokens = highlighter.tokenize("#text(\"Hello\")")
        let functions = tokens.filter { $0.type == .function }
        XCTAssert(functions.contains { $0.value == "#text" })
    }

    func testTokenizesString() {
        let tokens = highlighter.tokenize("\"hello world\"")
        let strings = tokens.filter { $0.type == .string }
        XCTAssertEqual(strings.count, 1)
        XCTAssertEqual(strings[0].value, "\"hello world\"")
    }

    func testTokenizesNumber() {
        let tokens = highlighter.tokenize("42")
        let numbers = tokens.filter { $0.type == .number }
        XCTAssertEqual(numbers.count, 1)
        XCTAssertEqual(numbers[0].value, "42")
    }

    func testTokenizesFloatingPointNumber() {
        let tokens = highlighter.tokenize("3.14")
        let numbers = tokens.filter { $0.type == .number }
        XCTAssertEqual(numbers.count, 1)
        XCTAssertEqual(numbers[0].value, "3.14")
    }

    func testTokenizesPunctuation() {
        let tokens = highlighter.tokenize("()")
        let punctuation = tokens.filter { $0.type == .punctuation }
        XCTAssertEqual(punctuation.count, 2)
    }

    func testTokenizesLineComment() {
        let tokens = highlighter.tokenize("// this is a comment\nx = 1")
        let comments = tokens.filter { $0.type == .comment }
        XCTAssertEqual(comments.count, 1)
        XCTAssert(comments[0].value.contains("// this is a comment"))
    }

    func testTokenizesBlockComment() {
        let tokens = highlighter.tokenize("/* multi\nline */ x")
        let comments = tokens.filter { $0.type == .comment }
        XCTAssertEqual(comments.count, 1)
    }

    func testTokenizesComplexExpression() {
        let code = "#let data = (\"name\": \"Alice\", \"age\": 30)"
        let tokens = highlighter.tokenize(code)

        let keywords = tokens.filter { $0.type == .keyword }
        let strings = tokens.filter { $0.type == .string }
        let numbers = tokens.filter { $0.type == .number }

        XCTAssert(keywords.count > 0)
        XCTAssert(strings.count > 0)
        XCTAssert(numbers.count > 0)
    }

    func testTokenizesMarkupPrefix() {
        let tokens = highlighter.tokenize("#myCustom()")
        let markupTokens = tokens.filter { $0.type == .markup }
        XCTAssert(markupTokens.count > 0)
        XCTAssert(markupTokens.contains { $0.value == "#myCustom" })
    }

    func testHandlesEmptyString() {
        let tokens = highlighter.tokenize("")
        XCTAssertEqual(tokens.count, 0)
    }

    func testHandlesWhitespaceOnly() {
        let tokens = highlighter.tokenize("   \n\t  ")
        XCTAssertEqual(tokens.count, 0)
    }
}

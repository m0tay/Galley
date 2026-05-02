# Galley: Typst REPL for macOS

Interactive development environment for Typst with live PDF rendering. Type Typst code, see the rendered PDF update in real-time.

## Architecture Overview

**Stack:** SwiftUI + Combine + async/await + TextKit 2

**Core Philosophy:**
- Functional programming for pure business logic (parsing, tokenization, state transforms)
- Reactive data flow via Combine (editor text → debounce → compile → render)
- Type-safe error handling with Result types
- Test-driven development from the ground up

## Project Structure

```
Galley/
├── Galley/                    # Main app target
│   ├── Core/                  # Pure business logic (testable, no GUI)
│   │   ├── CompilerService.swift    # Process management for typst binary
│   │   ├── OutputParser.swift       # Parse stderr into structured errors
│   │   ├── SyntaxHighlighter.swift  # Tokenize Typst code
│   │   └── DocumentStorage.swift    # Save/load documents
│   │
│   ├── Models/                # Data structures (immutable)
│   │   ├── Token.swift              # Syntax highlighting token
│   │   ├── CompilationError.swift   # Error with line/column
│   │   ├── Document.swift           # Codable document
│   │   └── EditorState.swift        # Observable view model (OOP)
│   │
│   ├── UI/                    # SwiftUI views
│   │   ├── MainWindow.swift         # Root container (editor + preview + errors)
│   │   ├── EditorView.swift         # Code editor with syntax highlighting
│   │   ├── PDFPreviewView.swift     # PDF rendering (PDFKit)
│   │   └── ErrorPanelView.swift     # Error list view
│   │
│   ├── Utilities/             # Helpers
│   │   ├── Process+Async.swift      # Async wrappers for Foundation.Process
│   │   └── FileManager+Ext.swift    # App support directory helpers
│   │
│   └── GalleyApp.swift        # @main entry point
│
├── GalleyTests/               # Test target
│   ├── Core/
│   │   ├── OutputParserTests.swift
│   │   ├── SyntaxHighlighterTests.swift
│   │   └── CompilerServiceTests.swift
│   │
│   ├── Models/
│   │   ├── DocumentTests.swift
│   │   └── EditorStateTests.swift
│   │
│   └── Mocks/
│       └── MockProcess.swift         # Testable Process replacement
│
├── Package.swift              # Swift Package manifest
└── .gitignore
```

## TDD Workflow

**Principle:** Write tests first, implement to make tests pass.

### Testing Layers

**Layer 1: Unit Tests (Pure Functions)**

Test business logic in isolation. These run fastest and catch regressions early.

```swift
// GalleyTests/Core/OutputParserTests.swift
import XCTest
@testable import Galley

class OutputParserTests: XCTestCase {
    let parser = OutputParser()
    
    func testParsesCompilationError() throws {
        let stderr = """
        error: function not found: `foo`
          ┌─ input.typ:5:2
          │
        5 │ #foo()
          │  ^^^ function not found
        """
        
        let errors = try parser.parse(stderr)
        
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0].line, 5)
        XCTAssertEqual(errors[0].column, 2)
        XCTAssert(errors[0].message.contains("function not found"))
    }
    
    func testHandlesMultipleErrors() throws {
        let stderr = """
        error: unknown variable: x
          ┌─ input.typ:1:1
        error: unknown variable: y
          ┌─ input.typ:2:1
        """
        
        let errors = try parser.parse(stderr)
        XCTAssertEqual(errors.count, 2)
    }
}
```

**Pattern:** Test the happy path, error cases, and edge cases (empty input, malformed output).

**Layer 2: Integration Tests (Mocked Dependencies)**

Test how components work together without external processes.

```swift
// GalleyTests/Models/EditorStateTests.swift
import XCTest
import Combine
@testable import Galley

class EditorStateTests: XCTestCase {
    var state: EditorState!
    var mockCompiler: MockCompiler!
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        super.setUp()
        mockCompiler = MockCompiler()
        state = EditorState(compiler: mockCompiler)
    }
    
    func testCompilationTriggersOnTextChange() throws {
        let expectation = XCTestExpectation(description: "Compilation triggered")
        
        mockCompiler.onCompile = { _ in
            expectation.fulfill()
        }
        
        state.editorText = "#let x = 5\n#x"
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDebouncesPreviousRequests() throws {
        // Type 3 times rapidly, should only compile once (at debounce deadline)
        let expectations = (0..<3).map { i in
            XCTestExpectation(description: "Compilation \(i)")
        }
        
        var compileCount = 0
        mockCompiler.onCompile = { _ in
            compileCount += 1
            if compileCount <= expectations.count {
                expectations[compileCount - 1].fulfill()
            }
        }
        
        state.editorText = "#a"
        state.editorText = "#b"
        state.editorText = "#c"
        
        // Should have only 1 compilation, not 3
        let result = XCTWaiter.wait(for: expectations, timeout: 1.0, enforceOrder: false)
        XCTAssertEqual(result, .timedOut) // One expectation never fulfilled
    }
}
```

**Pattern:** Use mock objects (protocol-based dependency injection) to isolate what you're testing.

**Layer 3: Snapshot Tests (Full Integration)**

Test the entire pipeline with real typst binary. Run these less frequently.

```swift
// GalleyTests/Integration/CompilationSnapshotTests.swift
import XCTest
@testable import Galley

class CompilationSnapshotTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipIf(!isTypstInstalled(), "typst not installed")
    }
    
    func testCompileSimpleText() async throws {
        let code = "Hello, *world*!"
        let pdf = try await CompilerService().compileTypst(code)
        
        // Compare PDF hash against baseline
        assertSnapshot(matching: pdf, as: .pdf, named: "simple-text")
    }
}
```

### Running Tests

```bash
# All tests
swift test

# Unit tests only
swift test -f UnitTests

# One test class
swift test --filter OutputParserTests

# Verbose output
swift test -v
```

## Dependency Injection Pattern

Use protocols to make components testable without external dependencies:

```swift
// Compiler interface (protocol, not concrete Process)
protocol Compiling {
    func compileTypst(_ source: String) async throws -> Data
}

// Real implementation
class CompilerService: Compiling {
    func compileTypst(_ source: String) async throws -> Data {
        // Spawn real typst process
    }
}

// Mock for testing
class MockCompiler: Compiling {
    var returnValue = Data()
    var shouldThrow: Error?
    
    func compileTypst(_ source: String) async throws -> Data {
        if let error = shouldThrow { throw error }
        return returnValue
    }
}

// Use in EditorState
class EditorState: ObservableObject {
    let compiler: any Compiling
    
    init(compiler: any Compiling = CompilerService()) {
        self.compiler = compiler
    }
}
```

**Benefit:** In tests, inject MockCompiler. In the app, inject CompilerService.

## Data Flow (Combine Pipeline)

```swift
class EditorState: ObservableObject {
    @Published var editorText = ""
    @Published var pdfData: Data?
    @Published var compilationError: CompilationError?
    @Published var isCompiling = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(compiler: any Compiling) {
        // Editor text → debounce → compile → update state
        $editorText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .setFailureType(to: Never.self)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.isCompiling = true
            })
            .asyncMap { [weak self] text -> Result<Data, CompilationError> in
                do {
                    let pdf = try await self?.compiler.compileTypst(text)
                    return .success(pdf ?? Data())
                } catch let error as CompilationError {
                    return .failure(error)
                } catch {
                    return .failure(.init(message: error.localizedDescription, line: nil, column: nil))
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.isCompiling = false
                switch result {
                case .success(let pdf):
                    self?.pdfData = pdf
                    self?.compilationError = nil
                case .failure(let error):
                    self?.compilationError = error
                    self?.pdfData = nil
                }
            }
            .store(in: &cancellables)
    }
}
```

**Key points:**
- Debounce prevents spawning typst on every keystroke
- Combine automatically cancels previous subscriptions when a new value arrives
- Errors are captured and displayed without crashing the app

## Syntax Highlighting

Implement a lightweight tokenizer (pure function):

```swift
enum TokenType {
    case keyword, function, variable, string, number, comment, punctuation
}

struct Token {
    let type: TokenType
    let range: NSRange
    let value: String
}

// Pure function (no side effects, easily testable)
func tokenize(_ code: String) -> [Token] {
    var tokens: [Token] = []
    // Scan code for patterns, emit tokens
    return tokens
}
```

**Testing:**
```swift
func testTokenizesFunction() {
    let tokens = tokenize("#let foo(x) = x + 1")
    XCTAssert(tokens.contains { $0.type == .keyword && $0.value == "let" })
    XCTAssert(tokens.contains { $0.type == .function && $0.value == "foo" })
}
```

## Error Handling

Typst errors have structure we can parse:

```
error: function not found: `foo`
  ┌─ input.typ:5:2
  │
5 │ #foo()
  │  ^^^ function not found
```

Parse this in OutputParser (pure function), represent as:

```swift
struct CompilationError: Identifiable {
    let id = UUID()
    let message: String
    let line: Int?
    let column: Int?
    let context: String?
}
```

The ErrorPanelView can then display these with clickable line numbers.

## Async/Await for Process Management

```swift
extension Process {
    func runAsync(input: Data) async throws -> (stdout: Data, stderr: Data) {
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        self.standardInput = inputPipe
        self.standardOutput = outputPipe
        self.standardError = errorPipe
        
        try self.run()
        
        // Write input on background queue
        let writeTask = Task {
            inputPipe.fileHandleForWriting.write(input)
            try inputPipe.fileHandleForWriting.close()
        }
        
        // Read output on background queue
        let readTask = Task {
            (
                stdout: outputPipe.fileHandleForReading.readDataToEndOfFile(),
                stderr: errorPipe.fileHandleForReading.readDataToEndOfFile()
            )
        }
        
        _ = await writeTask.result
        let (stdout, stderr) = try await readTask.value
        
        self.waitUntilExit()
        
        if self.terminationStatus != 0 {
            throw CompilationError(
                message: String(data: stderr, encoding: .utf8) ?? "Unknown error",
                line: nil,
                column: nil
            )
        }
        
        return (stdout, stderr)
    }
}
```

## Document Persistence

Store documents as YAML for human readability:

```yaml
id: 550e8400-e29b-41d4-a716-446655440000
lastCompiled: 2025-05-02T10:30:00Z
content: |
  #let items = ("apple", "banana", "cherry")
  
  #for item in items [
    - #item
  ]
```

Load/save via Codable:

```swift
struct Document: Codable {
    let id: UUID
    var content: String
    var lastCompiled: Date
    var fileURL: URL?
}

func save(_ doc: Document) throws {
    let encoder = YAMLEncoder()
    let yaml = try encoder.encode(doc)
    try yaml.write(to: doc.fileURL ?? defaultPath(), atomically: true, encoding: .utf8)
}
```

## Common Patterns

### Testing File I/O
```swift
func testDocumentSave() throws {
    let doc = Document(id: UUID(), content: "test", lastCompiled: Date())
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.yaml")
    
    try DocumentStorage().save(doc, to: tempURL)
    let loaded = try DocumentStorage().load(from: tempURL)
    
    XCTAssertEqual(loaded.content, doc.content)
}
```

### Testing UI State Changes
```swift
func testEditorStateUpdatesOnCompilationSuccess() {
    let state = EditorState(compiler: mockCompiler)
    mockCompiler.returnValue = testPDF
    
    state.editorText = "#text"
    
    XCTAssertEqual(state.pdfData, testPDF)
    XCTAssertNil(state.compilationError)
}
```

## Known Limitations

- Single document only (tab support in Phase 2)
- Syntax highlighting is basic (colors only, no code completion)
- No integrated package management (use system typst)
- Requires typst binary on PATH

## Next Steps (Phase 2)

- Multiple open documents (tab interface)
- Line-number clickable errors (jump to error location)
- Code completion for Typst builtins
- Dark mode support
- Document templates library

---

**Author:** Created with TDD-first approach  
**Language:** Swift 5.10+  
**Minimum macOS:** 12.0 (for async/await)

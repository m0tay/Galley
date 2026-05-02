<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS_12+-333?logo=apple&logoColor=white" alt="macOS 12+">
  <img src="https://img.shields.io/badge/swift-5.10+-F05138?logo=swift&logoColor=white" alt="Swift 5.10+">
  <img src="https://img.shields.io/badge/typst-required-239DAD" alt="Typst">
  <img src="https://img.shields.io/github/license/m0tay/Galley?color=blue" alt="License">
</p>

# Galley

**A live Typst editor with real-time PDF preview for macOS.**

Type Typst code on the left, see the rendered PDF update on the right — 500 ms after you stop typing. Compilation errors appear inline with line and column numbers. Syntax highlighting colors keywords, builtins, strings, numbers, and comments as you write.

Built for authors writing technical books in Typst who want a fast iterative loop for testing snippets — essentially a REPL experience for Typst.

---

## Features

| Feature | Details |
|---|---|
| **Live preview** | PDF renders 500 ms after last keystroke via PDFKit |
| **Syntax highlighting** | Keywords, builtins, strings, numbers, comments — all colored in real-time |
| **Error reporting** | Compilation errors shown with line/column and source context |
| **Debounced compilation** | Cancels previous in-flight compile on each new keystroke |
| **Native performance** | Pure Swift + AppKit — no Electron, no web views, 400 KB binary |
| **Zero dependencies** | SwiftUI, Combine, PDFKit, TextKit 2 — nothing third-party |

---

## Installation

### Option A — Download the app (fastest)

1. Go to [**Releases**](https://github.com/m0tay/Galley/releases/latest)
2. Download **`Galley-v1.0.0-macOS.zip`**
3. Unzip and drag **Galley.app** to `/Applications`
4. **Remove the quarantine flag** (required for unsigned apps):
   ```bash
   xattr -cr /Applications/Galley.app
   ```
5. Open **Galley.app** from `/Applications`

> **Why step 4?** macOS Gatekeeper quarantines apps downloaded from the internet. Since Galley is not notarized with an Apple Developer certificate, you must clear the quarantine attribute before the first launch. This is a one-time step.

### Option B — Build from source

```bash
git clone https://github.com/m0tay/Galley.git
cd Galley
swift build -c release
```

The binary is at `.build/release/Galley`. Run it directly or create an app bundle (see below).

### Option C — Build an app bundle

```bash
git clone https://github.com/m0tay/Galley.git
cd Galley
swift build -c release

# Create .app bundle
mkdir -p Galley.app/Contents/MacOS
cp .build/release/Galley Galley.app/Contents/MacOS/
cp Info.plist Galley.app/Contents/    # if you have one, or omit

# Move to Applications
mv Galley.app /Applications/
open /Applications/Galley.app
```

---

## Prerequisites

Galley requires the **Typst** compiler installed on your system.

```bash
# Install via Homebrew
brew install typst

# Verify it's available
typst --version
```

Galley searches for the binary in these locations (in order):

1. `/usr/local/bin/typst`
2. `/opt/homebrew/bin/typst` (Apple Silicon Homebrew)
3. `/usr/bin/typst`
4. Anywhere on your `$PATH`

If Typst is not found, the app shows a helpful error on launch.

---

## Usage

```bash
# Run from source
swift run Galley

# Or launch the .app
open /Applications/Galley.app
```

**The editor is ready to type immediately** — no click needed. Start writing Typst code:

```typst
= Hello, Galley!

#let name = "World"
This is a *live preview* of #name.

#table(
  columns: 3,
  [Name], [Age], [City],
  [Alice], [30], [NYC],
  [Bob], [25], [SF],
)
```

The PDF preview updates 500 ms after your last keystroke. If there's an error, it appears in the panel below the preview with the exact line and column.

---

## Architecture

```
Sources/
├── Galley/                     # Executable target (@main only)
│   └── GalleyApp.swift         # NSApplication.shared.run()
│
├── GalleyLib/                  # Library target (all logic + UI)
│   ├── AppDelegate.swift       # Window setup via NSSplitViewController
│   ├── Core/
│   │   ├── CompilerService.swift     # Async typst process management
│   │   ├── OutputParser.swift        # Parse stderr → CompilationError
│   │   └── SyntaxHighlighter.swift   # Tokenizer for Typst syntax
│   ├── Models/
│   │   ├── CompilationError.swift    # Error with line/column/context
│   │   ├── Document.swift            # Codable document model
│   │   ├── EditorState.swift         # ObservableObject + Combine pipeline
│   │   └── Token.swift               # Syntax token types
│   ├── UI/
│   │   ├── EditorView.swift          # AppKit NSTextView editor
│   │   ├── PDFPreviewView.swift      # PDFKit wrapper
│   │   ├── ErrorPanelView.swift      # Error display panel
│   │   ├── MainWindow.swift          # SwiftUI preview pane
│   │   └── TokenType+Color.swift     # Syntax color mapping
│   └── Utilities/
│       └── Process+Async.swift       # Async/await Process wrapper
│
Tests/
└── GalleyTests/
    ├── Core/                   # Unit tests (pure functions)
    ├── Models/                 # Integration tests (MockCompiler)
    └── Integration/            # Snapshot tests (real typst binary)
```

### Data flow

```
Keystroke → EditorViewController (AppKit NSTextView)
         → EditorState.editorText (Combine @Published)
         → debounce 500ms
         → CompilerService.compileTypst() (async, stdin → stdout)
         → Success: PDFPreviewView renders PDF via PDFKit
         → Failure: OutputParser extracts errors → ErrorPanelView
```

### Why AppKit for the editor?

SwiftUI's `WindowGroup` resets `NSWindow.firstResponder` after `viewDidAppear`, which permanently breaks keyboard input in embedded `NSTextView`. Galley uses `NSApplication` + `NSSplitViewController` directly — the editor owns its responder chain, and the preview pane uses SwiftUI via `NSHostingController`.

---

## Running tests

```bash
# All tests (unit + integration + snapshot)
swift test

# Just one test class
swift test --filter SyntaxHighlighterTests

# Verbose output
swift test -v
```

Snapshot tests compile real Typst code and verify the output is valid PDF. They are **automatically skipped** if `typst` is not installed.

---

## Tech stack

| Component | Technology |
|---|---|
| Editor | AppKit `NSTextView` + TextKit 2 |
| Preview | SwiftUI + PDFKit |
| State management | Combine (`@Published`, `debounce`) |
| Compilation | `Foundation.Process` with async/await |
| Syntax highlighting | Custom tokenizer → `NSTextStorage` attributes |
| Testing | XCTest, protocol-based mocks |

---

## License

MIT

---

<p align="center">
  <sub>Built with Swift and ☕ — for authors who think in Typst.</sub>
</p>

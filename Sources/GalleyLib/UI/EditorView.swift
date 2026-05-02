import AppKit

class EditorViewController: NSViewController {
    var onTextChange: ((String) -> Void)?
    private(set) var textView: NSTextView!

    override func loadView() {
        let scrollView = NSTextView.scrollableTextView()
        textView = scrollView.documentView as! NSTextView

        textView.delegate = self
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.labelColor
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 8, height: 8)

        self.view = scrollView
    }

    // viewDidAppear is reliable here because we're in a real AppKit
    // NSSplitViewController — not embedded inside SwiftUI's WindowGroup,
    // which resets first responder after viewDidAppear fires.
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(textView)
    }

    func setText(_ text: String) {
        guard isViewLoaded, textView.string != text else { return }
        let ranges = textView.selectedRanges
        textView.string = text
        textView.selectedRanges = ranges
        applyHighlighting(to: textView)
    }

    private func applyHighlighting(to textView: NSTextView) {
        guard let storage = textView.textStorage else { return }
        let text = textView.string
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        let tokens = SyntaxHighlighter().tokenize(text)

        storage.beginEditing()
        storage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
        for token in tokens {
            guard token.range.location + token.range.length <= fullRange.length else { continue }
            storage.addAttribute(.foregroundColor, value: token.type.highlightColor, range: token.range)
        }
        storage.endEditing()
    }
}

extension EditorViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        guard let tv = notification.object as? NSTextView else { return }
        applyHighlighting(to: tv)
        onTextChange?(tv.string)
    }
}

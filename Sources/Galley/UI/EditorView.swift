import SwiftUI
import AppKit

struct EditorView: View {
    @ObservedObject var state: EditorState

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Editor")
                    .font(.headline)
                Spacer()
                if state.isCompiling {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))

            TypstEditorTextView(text: $state.editorText)
        }
        .border(Color.gray.opacity(0.3))
    }
}

struct TypstEditorTextView: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.labelColor
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        if textView.string != text {
            textView.string = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
        }
    }
}

#if DEBUG
struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        let state = EditorState(compiler: MockCompiler())
        EditorView(state: state)
    }
}
#endif

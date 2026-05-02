import AppKit
import SwiftUI
import Combine

public class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var editorState: EditorState?
    private var cancellables = Set<AnyCancellable>()

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let state: EditorState
        do {
            state = EditorState(compiler: try CompilerService())
        } catch {
            state = EditorState(compiler: MockCompiler())
        }
        editorState = state

        // Left: pure AppKit text editor — owns the responder chain directly
        let editorVC = EditorViewController()
        editorVC.onTextChange = { [weak state] text in
            state?.editorText = text
        }
        // Push external editorText changes (e.g. load document) back into the view
        state.$editorText
            .removeDuplicates()
            .sink { [weak editorVC] text in
                editorVC?.setText(text)
            }
            .store(in: &cancellables)

        let editorItem = NSSplitViewItem(viewController: editorVC)
        editorItem.minimumThickness = 300

        // Right: SwiftUI preview pane via NSHostingController
        let previewVC = NSHostingController(rootView: PreviewPane(state: state))
        let previewItem = NSSplitViewItem(viewController: previewVC)
        previewItem.minimumThickness = 300

        // Add items BEFORE accessing splitView — accessing splitView forces
        // loadView(), and items must already be present so the split view
        // loads its subview hierarchy in one pass.
        let splitVC = NSSplitViewController()
        splitVC.addSplitViewItem(editorItem)
        splitVC.addSplitViewItem(previewItem)
        splitVC.splitView.isVertical = true
        splitVC.splitView.dividerStyle = .thin

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Galley"
        win.contentViewController = splitVC

        // Set editor pane to 400px so it's visible on launch
        splitVC.splitView.setPosition(400, ofDividerAt: 0)

        win.center()
        win.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)

        window = win
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

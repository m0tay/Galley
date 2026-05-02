import AppKit
import GalleyLib

@main
struct GalleyApp {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        let delegate = AppDelegate()
        app.delegate = delegate

        app.run()
    }
}

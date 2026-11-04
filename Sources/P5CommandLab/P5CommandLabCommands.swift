import AppKit
import SwiftUI

struct P5CommandLabCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            P5CommandLabOpenWindowButton(label: "About P5 Command Lab", windowID: "about")
        }

        CommandGroup(replacing: .help) {
            P5CommandLabOpenWindowButton(label: "P5 Command Lab Help", windowID: "help")
                .keyboardShortcut("?", modifiers: .command)

            Link("Full User Guide", destination: P5CommandLabLinks.userGuide)
            Link("Report an Issue", destination: P5CommandLabLinks.issues)

            Divider()

            Link("Visit code.matx.ca", destination: P5CommandLabLinks.website)
        }
    }
}

private struct P5CommandLabOpenWindowButton: View {
    let label: String
    let windowID: String
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(label) {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: windowID)
        }
    }
}

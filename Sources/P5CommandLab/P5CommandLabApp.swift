import SwiftUI

@main
struct P5CommandLabApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("P5 Command Lab") {
            ContentView().environmentObject(model)
        }
        .windowResizability(.contentSize)
        .commands {
            P5CommandLabCommands()
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Demo") {
                Button("Run Selected Command") { model.requestRun() }
                    .keyboardShortcut("r", modifiers: [.command])
                Button("Copy Command Preview") { model.copyPreview() }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                Divider()
                Button("Clear Console") { model.clearConsole() }
            }
        }

        Window("P5 Command Lab Output", id: "output") {
            DetachedOutputView().environmentObject(model)
        }
        .defaultSize(width: 760, height: 620)
        .windowResizability(.contentMinSize)

        Window("About P5 Command Lab", id: "about") {
            AboutP5CommandLabView()
        }
        .windowResizability(.contentSize)

        Window("P5 Command Lab Help", id: "help") {
            P5CommandLabHelpView()
        }
        .windowResizability(.contentSize)
    }
}

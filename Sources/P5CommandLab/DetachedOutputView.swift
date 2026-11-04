import AppKit
import SwiftUI

struct DetachedOutputView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.035, green: 0.055, blue: 0.075),
                    Color(red: 0.025, green: 0.022, blue: 0.035)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "terminal.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .shadow(color: .orange.opacity(0.7), radius: 5)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("P5 OUTPUT")
                            .font(.headline.monospaced().weight(.heavy))
                        Text(model.selectedRecipe.transport == .rest ? "JSON / jq-style result" : "nsdchat terminal result")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("Focus newest", isOn: $model.focusNewestOutput)
                        .toggleStyle(.checkbox)
                }

                TerminalOutputView(text: model.console, focusNewest: model.focusNewestOutput)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.5)))
                    .shadow(color: .orange.opacity(0.2), radius: 12)

                HStack {
                    Label("Floating presentation output", systemImage: "rectangle.on.rectangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Clear", action: model.clearConsole)
                    Button("Export Transcript…", action: model.exportConsole)
                }
            }
            .padding(16)
        }
        .preferredColorScheme(.dark)
        .background(FloatingWindowConfigurator())
        .frame(minWidth: 620, minHeight: 440)
    }
}

private struct FloatingWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { configure(view.window) }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async { configure(view.window) }
    }

    private func configure(_ window: NSWindow?) {
        window?.level = .floating
        window?.collectionBehavior.insert(.fullScreenAuxiliary)
        window?.title = "P5 Command Lab Output"
    }
}

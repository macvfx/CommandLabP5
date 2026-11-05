import AppKit
import Foundation
import P5CommandLabCore
import SwiftUI

@MainActor
final class P5InstallerDownloadModel: ObservableObject {
    @Published private(set) var installer: P5InstallerDownload?
    @Published private(set) var isLookingUp = false
    @Published private(set) var status = "Checking the standard nsdchat location…"
    @Published private(set) var localP5Status = "Not checked"

    let standardNsdchatPath = "/usr/local/aw/bin/nsdchat"

    var hasStandardNsdchat: Bool {
        FileManager.default.isExecutableFile(atPath: standardNsdchatPath)
    }

    func refresh() async {
        guard !isLookingUp else { return }
        isLookingUp = true
        defer { isLookingUp = false }
        await checkLocalP5Version()
        status = "Looking up the current official macOS installer…"

        do {
            var request = URLRequest(
                url: P5CommandLabLinks.p5Downloads,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                timeoutInterval: 20
            )
            request.setValue("P5 Command Lab", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let html = String(data: data, encoding: .utf8),
                  let found = P5InstallerDownloadParser.latestMacInstaller(
                    in: html,
                    downloadPage: P5CommandLabLinks.p5Downloads
                  ) else {
                throw InstallerLookupError.linkNotFound
            }
            installer = found
            let release = found.displayVersion.map { "P5 \($0), " } ?? ""
            status = "Found \(release)\(found.filename) on Archiware’s official download page."
        } catch {
            installer = nil
            status = "Automatic lookup failed: \(error.localizedDescription)"
        }
    }

    private func checkLocalP5Version() async {
        guard hasStandardNsdchat else {
            localP5Status = "nsdchat is not installed at the standard location."
            return
        }

        let command = ConstructedCommand(
            display: "nsdchat -c srvinfo lexxvers",
            executable: standardNsdchatPath,
            arguments: ["-c", "srvinfo", "lexxvers"],
            request: nil
        )
        do {
            let result = try await CommandRunner.run(command)
            let version = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            localP5Status = version.isEmpty || version == "(no output)"
                ? "nsdchat ran, but the local P5 service returned no version."
                : "Local P5 service: \(version)"
        } catch {
            localP5Status = "nsdchat is installed, but the local P5 service version could not be read: \(error.localizedDescription)"
        }
    }

    func downloadInstaller() {
        guard let installer else { return }
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = installer.displayVersion.map { "Download Archiware P5 \($0)?" } ?? "Download Archiware P5?"
        let release = installer.displayVersion.map { "P5 \($0) " } ?? ""
        alert.informativeText = "This opens the \(release)installer \(installer.filename) from Archiware’s official website in your default browser. It is the full P5 installer, not a standalone nsdchat package. Review the vendor’s licence and installation choices before authorizing changes to this Mac."
        alert.addButton(withTitle: "Download Installer")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(installer.url)
        }
    }

    func openDownloadPage() {
        NSWorkspace.shared.open(P5CommandLabLinks.p5Downloads)
    }
}

struct P5InstallerDownloadView: View {
    @StateObject private var model = P5InstallerDownloadModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: "shippingbox.and.arrow.backward")
                    .font(.system(size: 34))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Install Archiware P5").font(.title2.bold())
                    Text("Get the vendor installer that includes nsdchat")
                        .foregroundStyle(.secondary)
                }
            }

            GroupBox("nsdchat on this Mac") {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: model.hasStandardNsdchat ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(model.hasStandardNsdchat ? Color.green : Color.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.hasStandardNsdchat ? "Found at the standard P5 location" : "Not found at the standard P5 location")
                            .font(.headline)
                        Text(model.standardNsdchatPath)
                            .font(.system(.callout, design: .monospaced))
                            .textSelection(.enabled)
                        Text(model.localP5Status)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            Text("Archiware distributes nsdchat as part of the full P5 macOS installer. The installer may add or update P5 services and requires its own licence and administrator approval. P5 Command Lab finds the current official DMG but leaves download and installation to your browser and the vendor installer.")
                .fixedSize(horizontal: false, vertical: true)

            GroupBox("Official macOS installer") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        if model.isLookingUp {
                            ProgressView().controlSize(.small)
                        }
                        Text(model.status)
                            .font(.callout)
                            .textSelection(.enabled)
                    }

                    HStack {
                        if model.installer != nil {
                            Button("Download Installer…") {
                                model.downloadInstaller()
                            }
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut(.defaultAction)
                            .disabled(model.isLookingUp)
                        } else if !model.isLookingUp {
                            Button("Open Archiware Download Page") {
                                model.openDownloadPage()
                            }
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut(.defaultAction)
                        }

                        Button("Check Again") {
                            Task { await model.refresh() }
                        }
                        .disabled(model.isLookingUp)

                        if model.installer != nil {
                            Button("Open Download Page") {
                                model.openDownloadPage()
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Text("If Archiware changes its page or filename format, automatic lookup stops instead of guessing. Use the official download page fallback and select macOS New Install manually.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 650)
        .task { await model.refresh() }
    }
}

private enum InstallerLookupError: LocalizedError {
    case linkNotFound

    var errorDescription: String? {
        "No official awpst*-darwin.dmg link was present in the page."
    }
}

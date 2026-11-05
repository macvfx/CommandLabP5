import AppKit
import SwiftUI

struct AboutP5CommandLabView: View {
    @Environment(\.openWindow) private var openWindow

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 92, height: 92)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text("P5 Command Lab").font(.title.bold())
                Text("Version \(version) (\(build))").foregroundStyle(.secondary)
            }

            Text("Preview, explain, save, and run basic Archiware P5 REST API and nsdchat commands from a presentation-friendly macOS interface.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: 390)

            Label {
                Text("Server profiles and reviewed certificate fingerprints stay on this Mac, and live-profile passwords are stored in Keychain. The app contacts a configured P5 server only when you check a certificate or run a command from a live profile. Offline demo runs never use the network or launch nsdchat. The app contacts Archiware only when you request its installer or open a reference. It has no analytics, updater, account, or background service.")
            } icon: {
                Image(systemName: "hand.raised.fill").foregroundStyle(.tint)
            }
            .font(.callout)
            .padding(12)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 12) {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "help")
                } label: {
                    Label("Help", systemImage: "questionmark.circle")
                }
                Link("User Guide", destination: P5CommandLabLinks.userGuide)
            }

            Link("code.matx.ca", destination: P5CommandLabLinks.website)
                .font(.callout)

            Text("Copyright © 2026 Mat X")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(26)
        .frame(width: 440, height: 470)
    }
}

struct P5CommandLabHelpView: View {
    private enum Topic: String, CaseIterable, Identifiable {
        case quickStart = "Quick Start"
        case transports = "REST & nsdchat"
        case output = "Output & Recipes"
        case privacy = "Privacy & Help"
        case references = "References"
        var id: Self { self }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var topic: Topic = .quickStart

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 54, height: 54)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("P5 Command Lab Help").font(.title.bold())
                    Text("Preview and demonstrate P5 REST API and nsdchat commands")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(22)

            Picker("Help Topic", selection: $topic) {
                ForEach(Topic.allCases) { topic in
                    Text(topic.rawValue).tag(topic)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 22)
            .padding(.bottom, 14)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch topic {
                    case .quickStart: quickStart
                    case .transports: transports
                    case .output: output
                    case .privacy: privacy
                    case .references: references
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }

            Divider()

            HStack {
                Link("Full User Guide", destination: P5CommandLabLinks.userGuide)
                Spacer()
                Link("Report an Issue", destination: P5CommandLabLinks.issues)
                Spacer()
                Link("Source", destination: P5CommandLabLinks.repository)
            }
            .padding(18)
        }
        .frame(minWidth: 720, minHeight: 590)
    }

    private var quickStart: some View {
        Group {
            HelpSection(title: "1. Configure a server", icon: "server.rack") {
                Text("Use New to create a profile. Leave Demo Mode off to enter a live P5 host and credentials, or select Demo Mode to work entirely offline. Live-profile passwords can be stored in macOS Keychain.")
            }
            HelpSection(title: "2. Choose a recipe", icon: "list.bullet.rectangle") {
                Text("Every recipe is labelled REST or nsdchat. Required values appear below the picker, and the exact command updates before anything contacts the server.")
            }
            HelpSection(title: "3. Preview, then run", icon: "play.circle") {
                Text("Inspect the constructed command and keep the password redacted during presentations. Built-in recipes are read-only. Custom recipes require an additional confirmation because the app cannot classify arbitrary commands.")
            }
            HelpSection(title: "Offline demo", icon: "sparkles.rectangle.stack") {
                Text("Select Demo Mode in the P5 Server panel, then choose a scenario. The app shows an authentic fictional command and deterministic simulated result without contacting a server, launching nsdchat, reading Keychain credentials, or checking a certificate. Purple banners and transcript markers distinguish simulation from live evidence.")
            }
        }
    }

    private var transports: some View {
        Group {
            HelpSection(title: "REST API", icon: "network") {
                Text("REST recipes use HTTP Basic authentication and the selected HTTP or HTTPS endpoint, port, and API version. Results are formatted as JSON when possible.")
            }
            HelpSection(title: "HTTPS certificates", icon: "lock.shield") {
                Text("Use Check Certificate to inspect the subject and SHA-256 fingerprint. A reviewed self-signed certificate is saved for that exact host and port. If it changes, the connection is refused and the app asks you to review the replacement. HTTPS never falls back to HTTP.")
            }
            HelpSection(title: "Local nsdchat", icon: "desktopcomputer") {
                Text("Local direct mode runs nsdchat with -c. Local awfile mode adds the editable awfile connection before -c, matching P5's local lexxsrv service form.")
            }
            HelpSection(title: "Remote nsdchat", icon: "point.3.connected.trianglepath.dotted") {
                Text("Remote mode still runs the nsdchat binary installed on this Mac. It adds an awsock server argument containing the selected profile's host, port, username, and password.")
            }
            HelpSection(title: "Install P5 and nsdchat", icon: "shippingbox.and.arrow.backward") {
                Text("Choose Demo > Install Archiware P5 to check the standard nsdchat location, query the local P5 service with srvinfo lexxvers, and resolve the current macOS installer from Archiware's official download page. P5 Command Lab opens the vendor DMG in your browser; it does not silently install or update P5.")
            }
            HelpSection(title: "Server information", icon: "info.circle") {
                Text("Use the REST server-information recipe or the nsdchat lexxvers and uptime recipes to compare the two interfaces.")
            }
        }
    }

    private var output: some View {
        Group {
            HelpSection(title: "Presentation output", icon: "terminal") {
                Text("REST output uses jq-inspired colours. CLI output uses an amber terminal style. Focus newest dims older command/result blocks so the current result remains prominent.")
            }
            HelpSection(title: "Layouts", icon: "rectangle.split.2x1") {
                Text("Use Stacked for a compact screen, Side by Side for full-height results, or Detach Output for a resizable floating presentation window.")
            }
            HelpSection(title: "Custom recipes", icon: "slider.horizontal.3") {
                Text("A custom REST recipe stores a relative path and HTTP method. A custom nsdchat recipe stores the arguments after -c. Variables use braces, such as {volume} or {path}.")
            }
            HelpSection(title: "Read-only command packs", icon: "shippingbox") {
                Text("Choose Demo > Import Read-only Command Pack to load a versioned JSON pack. Imported commands are grouped by pack and may run only after the app validates their schema, placeholders, reserved headers, safety classification, and GET-only REST methods. Importing a pack with the same id replaces its earlier version.")
            }
            HelpSection(title: "Transcript export", icon: "doc.text") {
                Text("Export writes the visible console history to a text file. Review it before sharing because server responses may contain paths, hostnames, job metadata, or archive identifiers.")
            }
        }
    }

    private var privacy: some View {
        Group {
            HelpSection(title: "Stored locally", icon: "hand.raised.fill") {
                Text("Profiles, custom recipes, imported command packs, and explicitly trusted certificate fingerprints are stored in this user's app preferences. Passwords are stored separately in macOS Keychain. P5 Command Lab does not collect analytics, diagnostics, or usage information.")
            }
            HelpSection(title: "Network activity", icon: "antenna.radiowaves.left.and.right") {
                Text("Previewing, copying, and offline demo runs do not contact P5. Checking a certificate or running a recipe from a live profile contacts only the configured server. Installer lookup contacts Archiware's official download page only after its window opens. Help, source, support, and download links contact their destinations only when selected.")
            }
            HelpSection(title: "Share carefully", icon: "exclamationmark.triangle") {
                Text("Profiles, command previews with password reveal enabled, server responses, and exported transcripts can contain sensitive operational information. Redact them before screenshots, presentations, or issue reports.")
            }
            HelpSection(title: "More help", icon: "questionmark.circle") {
                Text("Use the Full User Guide for complete procedures and troubleshooting, or Report an Issue from the Help menu.")
                Link("Report an Issue", destination: P5CommandLabLinks.issues)
            }
        }
    }

    private var references: some View {
        Group {
            HelpSection(title: "P5Kit API examples", icon: "curlybraces.square") {
                Text("Curated, fictional REST request examples and integration notes from the independent P5Kit documentation project.")
                Link("Open P5Kit API Examples", destination: P5CommandLabLinks.p5KitExamples)
            }
            HelpSection(title: "Official P5 REST API", icon: "network") {
                Text("Archiware's authoritative REST resource and request reference. Check it against the API version enabled on the server.")
                Link("Open P5 REST API Reference", destination: P5CommandLabLinks.p5RESTAPI)
            }
            HelpSection(title: "Official nsdchat CLI manual", icon: "terminal") {
                Text("Archiware's command-line reference for nsdchat connection forms, resources, methods, arguments, and return values.")
                Link("Open P5 CLI Manual", destination: P5CommandLabLinks.p5CLIManual)
            }
            HelpSection(title: "Manuals for the installed version", icon: "books.vertical") {
                Text("Use the Archiware manuals hub to locate documentation appropriate to the P5 version installed at the site.")
                Link("Open Archiware Manuals & Guides", destination: P5CommandLabLinks.p5Manuals)
            }
            HelpSection(title: "Which source is authoritative?", icon: "checkmark.seal") {
                Text("Archiware's manuals define the supported P5 contract. P5Kit examples and P5 Command Lab supplement those manuals with integration and presentation examples; they do not replace vendor documentation.")
            }
        }
    }
}

private struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                content
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

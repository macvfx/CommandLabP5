import AppKit
import SwiftUI
import P5CommandLabCore

private enum WorkspaceLayout: String, CaseIterable {
    case stacked = "Stacked"
    case sideBySide = "Side by Side"
}

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow
    @AppStorage("workspaceLayout") private var workspaceLayout = WorkspaceLayout.stacked
    @State private var showingCertificateSheet = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.035, green: 0.075, blue: 0.11),
                    Color(red: 0.025, green: 0.035, blue: 0.055),
                    Color(red: 0.06, green: 0.035, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 13) {
                brandHeader
                if workspaceLayout == .sideBySide {
                    HStack(alignment: .top, spacing: 13) {
                        VStack(spacing: 13) {
                            connectionPanel
                            recipePanel
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                        consolePanel(expanded: true)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                } else {
                    connectionPanel
                    recipePanel
                    consolePanel(expanded: false)
                }
            }
            .padding(16)
        }
        .preferredColorScheme(.dark)
        .frame(
            minWidth: workspaceLayout == .sideBySide ? 1240 : 920,
            idealWidth: workspaceLayout == .sideBySide ? 1420 : 1060,
            minHeight: 760,
            idealHeight: 860
        )
        .sheet(isPresented: $model.showingCustomRecipe) {
            CustomRecipeView { model.saveCustomRecipe($0) }
        }
        .sheet(isPresented: $showingCertificateSheet) {
            CertificateTrustSheet(
                host: model.profile.host,
                port: model.profile.restPort,
                existingPin: model.profile.pinnedCertificateSHA256 ?? "",
                onTrust: model.trustCertificate
            )
        }
        .alert("The P5 Certificate Changed", isPresented: $model.showingCertificateChangedAlert) {
            Button("Review Certificate…") { showingCertificateSheet = true }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(model.certificateChangedDetail)
        }
        .confirmationDialog(
            "Run this custom command?",
            isPresented: $model.showingCustomExecutionWarning,
            titleVisibility: .visible
        ) {
            Button("Run Custom Command") { model.runConfirmed() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Built-in recipes are reviewed as read-only. A custom REST path or nsdchat command may change P5 state, so verify the constructed command first.")
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 48, height: 48)
                .shadow(color: .cyan.opacity(0.35), radius: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text("P5 COMMAND LAB")
                    .font(.system(size: 21, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .cyan.opacity(0.9)], startPoint: .leading, endPoint: .trailing)
                    )
                Text("REST API + nsdchat presentation console")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))
            }
            Spacer()
            Picker("Layout", selection: $workspaceLayout) {
                ForEach(WorkspaceLayout.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 190)
            Button {
                openWindow(id: "output")
            } label: {
                Label("Detach Output", systemImage: "macwindow.on.rectangle")
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            Label("P5 8 · REST v1", systemImage: "externaldrive.connected.to.line.below")
                .font(.caption.bold())
                .foregroundStyle(.cyan)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(.cyan.opacity(0.1), in: Capsule())
                .overlay(Capsule().stroke(.cyan.opacity(0.3)))
        }
    }

    private var connectionPanel: some View {
        GroupBox("P5 Server") {
            VStack(spacing: 10) {
                HStack {
                    Picker("Saved profile", selection: Binding(
                        get: { model.selectedProfileID },
                        set: { model.selectProfile($0) }
                    )) {
                        ForEach(model.profiles) { Text($0.name).tag($0.id) }
                    }
                    .frame(maxWidth: 360)
                    Button("New", action: model.newProfile)
                    Button("Save", action: model.saveProfile)
                    Button("Delete", role: .destructive, action: model.deleteProfile)
                    Spacer()
                    Toggle("HTTPS", isOn: $model.profile.useHTTPS)
                }
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        Text("Name")
                        TextField("Demo P5 Server", text: $model.profile.name)
                        Text("Host / IP")
                        TextField("p5.example.invalid", text: $model.profile.host)
                    }
                    GridRow {
                        Text("Username")
                        TextField("admin", text: $model.profile.username)
                        Text("Password")
                        HStack(spacing: 6) {
                            SecureField("Stored in Keychain", text: Binding(
                                get: { model.password },
                                set: { model.setPasswordDraft($0) }
                            ))
                            .onSubmit { model.savePassword() }
                            Button {
                                model.savePassword()
                            } label: {
                                Image(systemName: "key.fill")
                            }
                            .help("Store this password in macOS Keychain")
                            .disabled(model.password.isEmpty && model.credentialState == .missing)
                        }
                    }
                    GridRow {
                        Text("REST port")
                        TextField("8000", value: $model.profile.restPort, format: .number.grouping(.never))
                        Text("nsdchat port")
                        TextField("9001", value: $model.profile.nsdchatPort, format: .number.grouping(.never))
                    }
                    GridRow {
                        Text("API version")
                        TextField("v1", text: $model.profile.apiVersion)
                        Text("nsdchat path")
                        TextField("/usr/local/aw/bin/nsdchat", text: $model.profile.nsdchatPath)
                    }
                    GridRow {
                        Text("Local awfile")
                        TextField("awfile://usr/local/aw:lexxsrv", text: Binding(
                            get: { model.profile.awfileConnection ?? "" },
                            set: { model.profile.awfileConnection = $0 }
                        ))
                        .gridCellColumns(3)
                    }
                }
                .textFieldStyle(.roundedBorder)
                if model.profile.useHTTPS {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: model.profile.hasPinnedCertificate ? "lock.shield.fill" : "lock.shield")
                            .foregroundStyle(model.profile.hasPinnedCertificate ? .green : .orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(certificateStatus)
                                .font(.caption.bold())
                            if let fingerprint = model.profile.pinnedCertificateSHA256, !fingerprint.isEmpty {
                                Text(fingerprint)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                    .lineLimit(2)
                            }
                            Text("Self-signed certificates must be reviewed and saved once. If the certificate changes, the connection is refused. HTTPS never falls back to HTTP.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Check Certificate…") { showingCertificateSheet = true }
                            .disabled(model.profile.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.profile.hasPinnedCertificate {
                            Button("Forget Certificate", action: model.forgetCertificate)
                        }
                    }
                    .padding(.top, 2)
                }
                HStack {
                    Spacer()
                    Label(model.credentialState.message, systemImage: credentialSymbol)
                        .font(.caption)
                        .foregroundStyle(credentialColor)
                }
            }
        }
        .groupBoxStyle(LabGroupBoxStyle(accent: .cyan))
    }

    private var recipePanel: some View {
        GroupBox("Command") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Picker("Recipe", selection: Binding(
                        get: { model.selectedRecipeID },
                        set: { model.selectRecipe($0) }
                    )) {
                        Section("Built-in") {
                            ForEach(BuiltInRecipes.all) { recipe in
                                Text(recipe.transportLabeledName).tag(recipe.id)
                            }
                        }
                        ForEach(model.importedPacks) { pack in
                            Section(pack.title) {
                                ForEach(pack.recipes) { recipe in
                                    Text(recipe.transportLabeledName).tag(recipe.id)
                                }
                            }
                        }
                        if !model.customRecipes.isEmpty {
                            Section("Custom") {
                                ForEach(model.customRecipes) { recipe in
                                    Text(recipe.transportLabeledName).tag(recipe.id)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 390)
                    Text(model.selectedRecipe.transport.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(commandAccent)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(commandAccent.opacity(0.12), in: Capsule())
                        .overlay(Capsule().stroke(commandAccent.opacity(0.3)))
                    Spacer()
                    Button("Import Pack…", action: model.importCommandPack)
                    Button("New Custom…") { model.showingCustomRecipe = true }
                    if model.selectedRecipe.isImported {
                        Button("Remove Pack", role: .destructive, action: model.removeSelectedPack)
                    } else if !model.selectedRecipe.isBuiltIn {
                        Button("Delete Custom", role: .destructive, action: model.deleteSelectedRecipe)
                    }
                }
                Text(model.selectedRecipe.summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if model.selectedRecipe.isImported {
                    HStack(spacing: 8) {
                        Label("Imported · read-only", systemImage: "shippingbox.and.arrow.backward")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                        if let category = model.selectedRecipe.category { Text(category).font(.caption).foregroundStyle(.secondary) }
                        if let sourceTitle = model.selectedRecipe.sourceTitle,
                           let sourceValue = model.selectedRecipe.sourceURL,
                           let sourceURL = URL(string: sourceValue) {
                            Link(sourceTitle, destination: sourceURL).font(.caption)
                        }
                    }
                }

                if model.selectedRecipe.transport == .nsdchat {
                    Picker("Connection", selection: $model.cliConnection) {
                        ForEach(CLIConnection.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Text(cliConnectionExplanation)
                        .font(.caption).foregroundStyle(.secondary)
                }

                if !model.selectedRecipe.fields.isEmpty {
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                        ForEach(model.selectedRecipe.fields) { field in
                            GridRow {
                                Text(field.label).frame(width: 155, alignment: .trailing)
                                TextField(field.placeholder, text: Binding(
                                    get: { model.values[field.key] ?? "" },
                                    set: { model.values[field.key] = $0 }
                                ))
                            }
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                }

                Text("Constructed command")
                    .font(.caption.bold()).foregroundStyle(.secondary)
                ScrollView(.horizontal) {
                    Text(model.preview)
                        .font(.system(.body, design: .monospaced).weight(.medium))
                        .foregroundStyle(commandAccent)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(red: 0.015, green: 0.03, blue: 0.04), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(commandAccent.opacity(0.45)))
                .shadow(color: commandAccent.opacity(0.14), radius: 7)

                HStack {
                    Toggle("Reveal password in preview", isOn: $model.revealPassword)
                        .toggleStyle(.checkbox)
                    Spacer()
                    Button("Copy", action: model.copyPreview)
                    Button(model.isRunning ? "Running…" : (model.selectedRecipe.effectiveEffect == .readOnly ? "Run Read-only Command" : "Run Custom Command…"), action: model.requestRun)
                        .buttonStyle(.borderedProminent)
                        .tint(commandAccent)
                        .disabled(model.isRunning)
                }
            }
        }
        .groupBoxStyle(LabGroupBoxStyle(accent: commandAccent))
    }

    private func consolePanel(expanded: Bool) -> some View {
        GroupBox("Output") {
            VStack(spacing: 8) {
                HStack(spacing: 7) {
                    Circle().fill(Color.red.opacity(0.9)).frame(width: 9, height: 9)
                    Circle().fill(Color.yellow.opacity(0.9)).frame(width: 9, height: 9)
                    Circle().fill(Color.green.opacity(0.9)).frame(width: 9, height: 9)
                    Text(model.selectedRecipe.transport == .rest ? "JSON / jq-style output" : "nsdchat terminal output")
                        .font(.caption.monospaced().weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))
                    Spacer()
                    Toggle("Focus newest", isOn: $model.focusNewestOutput)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }
                TerminalOutputView(text: model.console, focusNewest: model.focusNewestOutput)
                    .frame(minHeight: 230, maxHeight: expanded ? .infinity : nil)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.orange.opacity(0.48)))
                    .shadow(color: .orange.opacity(0.18), radius: 10)
                HStack {
                    Text("Commands are read-only. Output may still contain server paths and operational metadata.")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Clear", action: model.clearConsole)
                    Button("Export Transcript…", action: model.exportConsole)
                }
            }
        }
        .groupBoxStyle(LabGroupBoxStyle(accent: .orange))
        .frame(maxHeight: expanded ? .infinity : nil)
    }

    private var commandAccent: Color {
        model.selectedRecipe.transport == .rest ? .cyan : .orange
    }

    private var cliConnectionExplanation: String {
        switch model.cliConnection {
        case .local:
            return "Local direct mode runs nsdchat -c … against P5 on this Mac."
        case .localAWFile:
            return "Local awfile mode adds -s \(model.profile.effectiveAWFileConnection), matching the local lexxsrv service form."
        case .remote:
            return "Remote mode runs the local nsdchat binary with -s awsock:/user:password@host:\(model.profile.nsdchatPort)."
        }
    }

    private var credentialColor: Color {
        switch model.credentialState {
        case .stored: return .green
        case .unsaved: return .orange
        case .missing: return .secondary
        case .error: return .red
        }
    }

    private var certificateStatus: String {
        if model.profile.hasPinnedCertificate {
            return model.profile.certificatePinMatchesEndpoint
                ? "Certificate saved for \(model.profile.host):\(model.profile.restPort)"
                : "Saved certificate belongs to another host or port — review required"
        }
        return "Using normal macOS certificate verification"
    }

    private var credentialSymbol: String {
        switch model.credentialState {
        case .stored: return "key.fill"
        case .unsaved: return "key.horizontal"
        case .missing: return "key.slash"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

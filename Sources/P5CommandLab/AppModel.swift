import AppKit
import Foundation
import P5CommandLabCore

enum CredentialState: Equatable {
    case missing
    case unsaved
    case stored
    case error(String)

    var message: String {
        switch self {
        case .missing: return "No password stored"
        case .unsaved: return "Password changed — not stored yet"
        case .stored: return "Password stored in Keychain"
        case .error(let message): return "Keychain: \(message)"
        }
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var profiles: [ServerProfile]
    @Published var selectedProfileID: UUID
    @Published var profile: ServerProfile
    @Published var password: String
    @Published var credentialState: CredentialState
    @Published var customRecipes: [CommandRecipe]
    @Published var selectedRecipeID: UUID
    @Published var values: [String: String] = [:]
    @Published var cliConnection: CLIConnection = .local
    @Published var revealPassword = false
    @Published var focusNewestOutput = true
    @Published var console = "P5 Command Lab is ready. Previewing commands never contacts the server.\n"
    @Published var isRunning = false
    @Published var showingCustomRecipe = false
    @Published var showingCustomExecutionWarning = false
    @Published var showingCertificateChangedAlert = false
    @Published var certificateChangedDetail = ""

    private let profilesKey = "serverProfiles.v1"
    private let customRecipesKey = "customRecipes.v1"

    init() {
        let loadedProfiles: [ServerProfile] = Self.load(profilesKey) ?? [ServerProfile()]
        let loadedCustom: [CommandRecipe] = Self.load(customRecipesKey) ?? []
        profiles = loadedProfiles
        profile = loadedProfiles[0]
        selectedProfileID = loadedProfiles[0].id
        switch KeychainStore.loadPassword(for: loadedProfiles[0].id) {
        case .found(let storedPassword):
            password = storedPassword
            credentialState = .stored
        case .missing:
            password = ""
            credentialState = .missing
        case .failed(let status):
            password = ""
            credentialState = .error(KeychainStore.message(for: status))
        }
        customRecipes = loadedCustom
        selectedRecipeID = BuiltInRecipes.all[0].id
        resetValues()
    }

    var recipes: [CommandRecipe] { BuiltInRecipes.all + customRecipes }

    var selectedRecipe: CommandRecipe {
        recipes.first(where: { $0.id == selectedRecipeID }) ?? BuiltInRecipes.all[0]
    }

    var preview: String {
        do { return try command().display }
        catch { return "Cannot construct command: \(error.localizedDescription)" }
    }

    func command() throws -> ConstructedCommand {
        try CommandBuilder.construct(
            recipe: selectedRecipe,
            profile: profile,
            password: password,
            values: values,
            cliConnection: cliConnection,
            revealPassword: revealPassword
        )
    }

    func selectProfile(_ id: UUID) {
        guard let selected = profiles.first(where: { $0.id == id }) else { return }
        selectedProfileID = id
        profile = selected
        switch KeychainStore.loadPassword(for: id) {
        case .found(let storedPassword):
            password = storedPassword
            credentialState = .stored
        case .missing:
            password = ""
            credentialState = .missing
        case .failed(let status):
            password = ""
            credentialState = .error(KeychainStore.message(for: status))
        }
    }

    func setPasswordDraft(_ value: String) {
        password = value
        credentialState = value.isEmpty ? .missing : .unsaved
    }

    @discardableResult
    func savePassword(reportToConsole: Bool = true) -> Bool {
        switch KeychainStore.save(password: password, for: profile.id, label: profile.name) {
        case .saved:
            credentialState = .stored
            if reportToConsole { append("Password stored in Keychain for “\(profile.name)”.") }
            return true
        case .removed:
            credentialState = .missing
            if reportToConsole { append("Removed the stored password for “\(profile.name)”.") }
            return true
        case .failed(let status):
            let message = KeychainStore.message(for: status)
            credentialState = .error(message)
            if reportToConsole { append("ERROR  Could not update Keychain: \(message)") }
            return false
        }
    }

    func newProfile() {
        let newProfile = ServerProfile(name: "New P5 Server")
        profiles.append(newProfile)
        persistProfiles()
        selectProfile(newProfile.id)
    }

    func saveProfile() {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        selectedProfileID = profile.id
        let passwordSaved = savePassword(reportToConsole: false)
        persistProfiles()
        append(passwordSaved
               ? "Saved server profile “\(profile.name)” and its Keychain password."
               : "Saved server profile “\(profile.name)”, but the Keychain password could not be updated.")
    }

    func trustCertificate(_ fingerprint: String) {
        if fingerprint.isEmpty {
            profile.useSystemCertificateTrust()
            append("Using normal macOS certificate verification for “\(profile.name)”.")
        } else {
            profile.trustCertificate(fingerprint)
            append("Trusted the reviewed certificate for “\(profile.name)” at \(profile.host):\(profile.restPort).")
        }
        updateCurrentProfileAndPersist()
    }

    func forgetCertificate() {
        profile.useSystemCertificateTrust()
        updateCurrentProfileAndPersist()
        append("Forgot the saved certificate for “\(profile.name)”. HTTPS now requires normal macOS trust until another certificate is reviewed.")
    }

    func deleteProfile() {
        guard profiles.count > 1 else {
            append("Keep at least one server profile.")
            return
        }
        KeychainStore.delete(profileID: profile.id)
        profiles.removeAll { $0.id == profile.id }
        persistProfiles()
        selectProfile(profiles[0].id)
    }

    func selectRecipe(_ id: UUID) {
        selectedRecipeID = id
        resetValues()
    }

    func resetValues() {
        values = Dictionary(uniqueKeysWithValues: selectedRecipe.fields.map { ($0.key, $0.defaultValue) })
    }

    func saveCustomRecipe(_ recipe: CommandRecipe) {
        customRecipes.append(recipe)
        persistCustomRecipes()
        selectRecipe(recipe.id)
        append("Saved custom recipe “\(recipe.name)”.")
    }

    func deleteSelectedRecipe() {
        guard !selectedRecipe.isBuiltIn else { return }
        customRecipes.removeAll { $0.id == selectedRecipeID }
        persistCustomRecipes()
        selectRecipe(BuiltInRecipes.all[0].id)
    }

    func copyPreview() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(preview, forType: .string)
        append(revealPassword ? "Copied the command preview with its password visible." : "Copied the redacted command preview.")
    }

    func requestRun() {
        if selectedRecipe.isBuiltIn {
            runConfirmed()
        } else {
            showingCustomExecutionWarning = true
        }
    }

    func runConfirmed() {
        guard !isRunning else { return }
        if credentialState == .unsaved {
            _ = savePassword(reportToConsole: false)
        }
        if profile.useHTTPS && profile.hasPinnedCertificate && !profile.certificatePinMatchesEndpoint {
            append("ERROR  \(P5TLSFailure.pinBelongsToAnotherEndpoint.localizedDescription)")
            return
        }
        let built: ConstructedCommand
        do { built = try command() }
        catch { append("ERROR  \(error.localizedDescription)"); return }

        isRunning = true
        append("COMMAND\n\(built.display)")
        Task {
            do {
                let result = try await CommandRunner.run(built, certificatePin: profile.certificatePinForCurrentEndpoint)
                append("RESULT  \(result.status)\n\(result.output)")
            } catch {
                if case let P5TLSFailure.certificateChanged(expected, presented) = error {
                    certificateChangedDetail = "Trusted \(P5TLSFailure.short(expected)); the server presented \(P5TLSFailure.short(presented)). The connection was refused."
                    showingCertificateChangedAlert = true
                }
                append("ERROR  \(Self.connectionMessage(for: error))")
            }
            isRunning = false
        }
    }

    func clearConsole() {
        console = ""
    }

    func exportConsole() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "P5-Command-Lab-Transcript.txt"
        panel.allowedContentTypes = [.plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try console.write(to: url, atomically: true, encoding: .utf8)
            append("Exported transcript to \(url.path).")
        } catch {
            append("ERROR  Could not export transcript: \(error.localizedDescription)")
        }
    }

    private func append(_ text: String) {
        let stamp = Date.now.formatted(date: .omitted, time: .standard)
        if !console.isEmpty, !console.hasSuffix("\n") { console += "\n" }
        console += "\n[\(stamp)] \(text)\n"
    }

    private func persistProfiles() { Self.save(profiles, key: profilesKey) }
    private func persistCustomRecipes() { Self.save(customRecipes, key: customRecipesKey) }

    private static func load<T: Decodable>(_ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func updateCurrentProfileAndPersist() {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        }
        persistProfiles()
    }

    private static func connectionMessage(for error: Error) -> String {
        if let tls = error as? P5TLSFailure { return tls.localizedDescription }
        guard let urlError = error as? URLError else { return error.localizedDescription }
        switch urlError.code {
        case .serverCertificateUntrusted, .serverCertificateHasUnknownRoot,
             .serverCertificateHasBadDate, .serverCertificateNotYetValid, .secureConnectionFailed:
            return "The P5 certificate could not be verified. Use Check Certificate to review its subject and SHA-256 fingerprint. No HTTP fallback was attempted."
        case .timedOut:
            return "Connection timed out contacting P5."
        case .cannotFindHost, .dnsLookupFailed:
            return "The P5 server name could not be resolved."
        case .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
            return "Could not connect to the P5 server."
        default:
            return urlError.localizedDescription
        }
    }
}

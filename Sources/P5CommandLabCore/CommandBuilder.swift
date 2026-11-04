import Foundation

public enum CommandBuilder {
    public static func construct(
        recipe: CommandRecipe,
        profile: ServerProfile,
        password: String,
        values: [String: String],
        cliConnection: CLIConnection,
        revealPassword: Bool
    ) throws -> ConstructedCommand {
        guard (1...65_535).contains(profile.restPort),
              (1...65_535).contains(profile.nsdchatPort) else {
            throw CommandLabError.invalidPort
        }

        switch recipe.transport {
        case .rest:
            return try restCommand(recipe: recipe, profile: profile, password: password, values: values, revealPassword: revealPassword)
        case .nsdchat:
            return try cliCommand(recipe: recipe, profile: profile, password: password, values: values, connection: cliConnection, revealPassword: revealPassword)
        }
    }

    private static func restCommand(
        recipe: CommandRecipe,
        profile: ServerProfile,
        password: String,
        values: [String: String],
        revealPassword: Bool
    ) throws -> ConstructedCommand {
        let path = try substitute(recipe.template, fields: recipe.fields, values: values)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var components = URLComponents()
        components.scheme = profile.useHTTPS ? "https" : "http"
        components.host = profile.host.trimmingCharacters(in: .whitespacesAndNewlines)
        components.port = profile.restPort
        components.path = "/rest/\(profile.apiVersion)/\(path)"
        guard let url = components.url else { throw CommandLabError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = recipe.method.uppercased()
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let credential = Data("\(profile.username):\(password)".utf8).base64EncodedString()
        request.setValue("Basic \(credential)", forHTTPHeaderField: "Authorization")

        var displayParts = ["curl", "-sS", "-u", shellQuote("\(profile.username):\(revealPassword ? password : "••••••")"), "-H", shellQuote("Accept: application/json")]
        for key in recipe.headerTemplates.keys.sorted() {
            let value = try substitute(recipe.headerTemplates[key] ?? "", fields: recipe.fields, values: values)
            if value.isEmpty { continue }
            request.setValue(value, forHTTPHeaderField: key)
            displayParts += ["-H", shellQuote("\(key): \(value)")]
        }
        if recipe.method.uppercased() != "GET" {
            displayParts += ["-X", recipe.method.uppercased()]
        }
        displayParts.append(shellQuote(url.absoluteString))
        return ConstructedCommand(display: displayParts.joined(separator: " "), executable: nil, arguments: [], request: request)
    }

    private static func cliCommand(
        recipe: CommandRecipe,
        profile: ServerProfile,
        password: String,
        values: [String: String],
        connection: CLIConnection,
        revealPassword: Bool
    ) throws -> ConstructedCommand {
        let commandText = try substitute(recipe.template, fields: recipe.fields, values: values)
        let commandArguments = splitCommand(commandText)
        var arguments: [String] = []
        var displayArguments: [String] = []
        switch connection {
        case .local:
            break
        case .localAWFile:
            arguments += ["-s", profile.effectiveAWFileConnection]
            displayArguments += ["-s", profile.effectiveAWFileConnection]
        case .remote:
            let actual = "awsock:/\(profile.username):\(password)@\(profile.host):\(profile.nsdchatPort)"
            let shown = "awsock:/\(profile.username):\(revealPassword ? password : "••••••")@\(profile.host):\(profile.nsdchatPort)"
            arguments += ["-s", actual]
            displayArguments += ["-s", shown]
        }
        arguments.append("-c")
        arguments += commandArguments
        displayArguments.append("-c")
        displayArguments += commandArguments
        let display = ([shellQuote(profile.nsdchatPath)] + displayArguments.map(shellQuote)).joined(separator: " ")
        return ConstructedCommand(display: display, executable: profile.nsdchatPath, arguments: arguments, request: nil)
    }

    public static func substitute(
        _ template: String,
        fields: [RecipeField],
        values: [String: String]
    ) throws -> String {
        var result = template
        for field in fields {
            let value = (values[field.key] ?? field.defaultValue).trimmingCharacters(in: .whitespacesAndNewlines)
            let token = "{\(field.key)}"
            if result.contains(token), value.isEmpty, !field.label.localizedCaseInsensitiveContains("optional") {
                throw CommandLabError.missingValue(field.label)
            }
            result = result.replacingOccurrences(of: token, with: value)
        }
        return result.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
    }

    public static func shellQuote(_ text: String) -> String {
        if !text.isEmpty, text.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_./:-")).contains($0) }) {
            return text
        }
        return "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// A small shell-like tokenizer. It understands whitespace, single/double quotes and backslash.
    /// Commands are still executed directly with Process; no shell is involved.
    public static func splitCommand(_ text: String) -> [String] {
        var result: [String] = []
        var current = ""
        var quote: Character?
        var escaped = false
        for character in text {
            if escaped { current.append(character); escaped = false; continue }
            if character == "\\" { escaped = true; continue }
            if let activeQuote = quote {
                if character == activeQuote { quote = nil } else { current.append(character) }
                continue
            }
            if character == "\"" || character == "'" { quote = character; continue }
            if character.isWhitespace {
                if !current.isEmpty { result.append(current); current = "" }
            } else {
                current.append(character)
            }
        }
        if escaped { current.append("\\") }
        if !current.isEmpty { result.append(current) }
        return result
    }
}

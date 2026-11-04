import Foundation

public struct ServerProfile: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var host: String
    public var restPort: Int
    public var nsdchatPort: Int
    public var username: String
    public var apiVersion: String
    public var useHTTPS: Bool
    public var nsdchatPath: String
    public var awfileConnection: String?
    public var pinnedCertificateSHA256: String?
    public var pinnedCertificateHost: String?
    public var pinnedCertificatePort: Int?

    public init(
        id: UUID = UUID(),
        name: String = "Demo P5 Server",
        host: String = "127.0.0.1",
        restPort: Int = 8000,
        nsdchatPort: Int = 9001,
        username: String = "admin",
        apiVersion: String = "v1",
        useHTTPS: Bool = false,
        nsdchatPath: String = "/usr/local/aw/bin/nsdchat",
        awfileConnection: String? = nil,
        pinnedCertificateSHA256: String? = nil,
        pinnedCertificateHost: String? = nil,
        pinnedCertificatePort: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.restPort = restPort
        self.nsdchatPort = nsdchatPort
        self.username = username
        self.apiVersion = apiVersion
        self.useHTTPS = useHTTPS
        self.nsdchatPath = nsdchatPath
        self.awfileConnection = awfileConnection
        self.pinnedCertificateSHA256 = pinnedCertificateSHA256
        self.pinnedCertificateHost = pinnedCertificateHost
        self.pinnedCertificatePort = pinnedCertificatePort
    }

    public var effectiveAWFileConnection: String {
        let value = awfileConnection?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "awfile://usr/local/aw:lexxsrv" : value
    }

    public var hasPinnedCertificate: Bool {
        !(pinnedCertificateSHA256 ?? "").isEmpty
    }

    public var certificatePinMatchesEndpoint: Bool {
        guard hasPinnedCertificate else { return true }
        return pinnedCertificateHost?.caseInsensitiveCompare(host) == .orderedSame
            && pinnedCertificatePort == restPort
    }

    public var certificatePinForCurrentEndpoint: String? {
        guard useHTTPS, certificatePinMatchesEndpoint else { return nil }
        return pinnedCertificateSHA256?.isEmpty == false ? pinnedCertificateSHA256 : nil
    }

    public mutating func trustCertificate(_ fingerprint: String) {
        pinnedCertificateSHA256 = fingerprint
        pinnedCertificateHost = host
        pinnedCertificatePort = restPort
    }

    public mutating func useSystemCertificateTrust() {
        pinnedCertificateSHA256 = nil
        pinnedCertificateHost = nil
        pinnedCertificatePort = nil
    }
}

public enum RecipeTransport: String, Codable, CaseIterable, Sendable {
    case rest = "REST API"
    case nsdchat = "nsdchat CLI"
}

public enum CLIConnection: String, Codable, CaseIterable, Sendable {
    case local = "Local direct"
    case localAWFile = "Local via awfile"
    case remote = "Remote over awsock"
}

public enum RecipeEffect: String, Codable, CaseIterable, Sendable {
    case readOnly = "read-only"
    case mutating
    case startsJob = "starts-job"
    case unknown
}

public struct RecipeField: Identifiable, Codable, Hashable, Sendable {
    public var id: String { key }
    public let key: String
    public let label: String
    public let placeholder: String
    public let defaultValue: String

    public init(_ key: String, label: String, placeholder: String = "", defaultValue: String = "") {
        self.key = key
        self.label = label
        self.placeholder = placeholder
        self.defaultValue = defaultValue
    }
}

public struct CommandRecipe: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var summary: String
    public var transport: RecipeTransport
    public var method: String
    public var template: String
    public var headerTemplates: [String: String]
    public var fields: [RecipeField]
    public var isBuiltIn: Bool
    public var effect: RecipeEffect?
    public var packID: String?
    public var category: String?
    public var comparisonID: String?
    public var sourceTitle: String?
    public var sourceURL: String?
    public var sourceReference: String?
    public var minimumP5Version: String?

    public init(
        id: UUID = UUID(),
        name: String,
        summary: String,
        transport: RecipeTransport,
        method: String = "GET",
        template: String,
        headerTemplates: [String: String] = [:],
        fields: [RecipeField] = [],
        isBuiltIn: Bool = false,
        effect: RecipeEffect? = nil,
        packID: String? = nil,
        category: String? = nil,
        comparisonID: String? = nil,
        sourceTitle: String? = nil,
        sourceURL: String? = nil,
        sourceReference: String? = nil,
        minimumP5Version: String? = nil
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.transport = transport
        self.method = method
        self.template = template
        self.headerTemplates = headerTemplates
        self.fields = fields
        self.isBuiltIn = isBuiltIn
        self.effect = effect
        self.packID = packID
        self.category = category
        self.comparisonID = comparisonID
        self.sourceTitle = sourceTitle
        self.sourceURL = sourceURL
        self.sourceReference = sourceReference
        self.minimumP5Version = minimumP5Version
    }

    public var transportLabeledName: String {
        let label = transport == .rest ? "REST" : "nsdchat"
        if name.localizedCaseInsensitiveContains("— \(label)") { return name }
        return "\(name) — \(label)"
    }

    public var effectiveEffect: RecipeEffect {
        effect ?? (isBuiltIn ? .readOnly : .unknown)
    }

    public var isImported: Bool { packID != nil }
}

public struct CommandPackSource: Codable, Hashable, Sendable {
    public var title: String
    public var url: String

    public init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}

public struct CommandPack: Identifiable, Codable, Hashable, Sendable {
    public var schemaVersion: Int
    public var id: String
    public var title: String
    public var version: String
    public var summary: String
    public var sources: [CommandPackSource]
    public var recipes: [CommandRecipe]

    public init(schemaVersion: Int = 1, id: String, title: String, version: String, summary: String, sources: [CommandPackSource] = [], recipes: [CommandRecipe]) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.title = title
        self.version = version
        self.summary = summary
        self.sources = sources
        self.recipes = recipes
    }
}

public enum CommandPackError: LocalizedError, Equatable {
    case unsupportedSchema(Int)
    case missingPackIdentity
    case duplicateRecipeID
    case emptyRecipes
    case unsafeRecipe(String, RecipeEffect)
    case nonGETRESTRecipe(String)
    case reservedHeader(String, String)
    case invalidTemplate(String, String)
    case invalidSourceURL(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedSchema(let version): return "Command pack schema version \(version) is not supported."
        case .missingPackIdentity: return "The command pack needs a non-empty id, title, and version."
        case .duplicateRecipeID: return "Every command in a pack must have a unique UUID."
        case .emptyRecipes: return "The command pack does not contain any commands."
        case .unsafeRecipe(let name, let effect): return "“\(name)” is marked \(effect.rawValue). Version 0.2 imports read-only commands only."
        case .nonGETRESTRecipe(let name): return "“\(name)” uses a REST method other than GET. Version 0.2 imports GET recipes only."
        case .reservedHeader(let name, let header): return "“\(name)” cannot define the reserved \(header) header."
        case .invalidTemplate(let name, let detail): return "“\(name)” has an invalid template: \(detail)"
        case .invalidSourceURL(let value): return "The source URL is invalid: \(value)"
        }
    }
}

public enum CommandPackLoader {
    public static func decode(_ data: Data) throws -> CommandPack {
        let pack = try JSONDecoder().decode(CommandPack.self, from: data)
        return try validate(pack)
    }

    public static func validate(_ input: CommandPack) throws -> CommandPack {
        guard input.schemaVersion == 1 else { throw CommandPackError.unsupportedSchema(input.schemaVersion) }
        guard !input.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !input.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !input.version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommandPackError.missingPackIdentity
        }
        guard !input.recipes.isEmpty else { throw CommandPackError.emptyRecipes }
        guard Set(input.recipes.map(\.id)).count == input.recipes.count else { throw CommandPackError.duplicateRecipeID }
        for source in input.sources {
            guard let url = URL(string: source.url), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
                throw CommandPackError.invalidSourceURL(source.url)
            }
        }

        var pack = input
        for index in pack.recipes.indices {
            var recipe = pack.recipes[index]
            guard recipe.effectiveEffect == .readOnly else { throw CommandPackError.unsafeRecipe(recipe.name, recipe.effectiveEffect) }
            if recipe.transport == .rest && recipe.method.uppercased() != "GET" {
                throw CommandPackError.nonGETRESTRecipe(recipe.name)
            }
            for key in recipe.headerTemplates.keys where ["authorization", "host", "cookie"].contains(key.lowercased()) {
                throw CommandPackError.reservedHeader(recipe.name, key)
            }
            let fieldKeys = Set(recipe.fields.map(\.key))
            let templates = [recipe.template] + Array(recipe.headerTemplates.values)
            for template in templates {
                for token in tokens(in: template) where !fieldKeys.contains(token) {
                    throw CommandPackError.invalidTemplate(recipe.name, "unknown placeholder {\(token)}")
                }
            }
            if recipe.transport == .rest {
                let lower = recipe.template.lowercased()
                if lower.hasPrefix("http://") || lower.hasPrefix("https://") || lower.contains("..") {
                    throw CommandPackError.invalidTemplate(recipe.name, "REST templates must be relative paths without '..'")
                }
            }
            recipe.isBuiltIn = false
            recipe.packID = pack.id
            recipe.effect = .readOnly
            pack.recipes[index] = recipe
        }
        return pack
    }

    private static func tokens(in template: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: #"(?<!\{)\{([A-Za-z][A-Za-z0-9_-]*)\}(?!\})"#) else { return [] }
        let range = NSRange(template.startIndex..., in: template)
        return regex.matches(in: template, range: range).compactMap { match in
            guard let swiftRange = Range(match.range(at: 1), in: template) else { return nil }
            return String(template[swiftRange])
        }
    }
}

public enum BuiltInRecipes {
    public static let all: [CommandRecipe] = [
        .init(name: "Server version & uptime", summary: "P5 release, build, platform, hostname and uptime.", transport: .rest, template: "general/srvinfo", isBuiltIn: true),
        .init(name: "Server version — nsdchat", summary: "Reads the P5 lexxvers value through nsdchat; choose local direct, local awfile, or remote awsock.", transport: .nsdchat, template: "srvinfo lexxvers", isBuiltIn: true),
        .init(name: "Server uptime — nsdchat", summary: "Reads P5 server uptime through nsdchat; choose local direct, local awfile, or remote awsock.", transport: .nsdchat, template: "srvinfo uptime", isBuiltIn: true),
        .init(name: "Volumes — REST", summary: "Lists all volumes known to the P5 server.", transport: .rest, template: "general/volumes", isBuiltIn: true),
        .init(name: "Archive volumes — REST", summary: "Uses the volume list; entries whose usage is Archive are archive media. The REST API does not provide a separate archive-only list.", transport: .rest, template: "general/volumes", isBuiltIn: true),
        .init(name: "Volumes — nsdchat", summary: "Lists volume IDs through the local CLI.", transport: .nsdchat, template: "Volume names", isBuiltIn: true),
        .init(name: "Volume usage", summary: "Shows whether a volume is used by Archive, Backup, or another module.", transport: .nsdchat, template: "Volume {volume} usage", fields: [.init("volume", label: "Volume ID", placeholder: "TAPE001")], isBuiltIn: true),
        .init(name: "Archive indexes — REST", summary: "Lists archive indexes available through REST.", transport: .rest, template: "archive/indexes", isBuiltIn: true),
        .init(name: "Archive indexes — nsdchat", summary: "Lists archive index names through the CLI.", transport: .nsdchat, template: "ArchiveIndex names", isBuiltIn: true),
        .init(name: "Archive plans", summary: "Lists configured archive plans.", transport: .rest, template: "archive/plans", isBuiltIn: true),
        .init(name: "Archive overview", summary: "REST-only overview of finished archive jobs and pool capacity.", transport: .rest, template: "archive/overview", isBuiltIn: true),
        .init(name: "Jukeboxes", summary: "Lists tape libraries and jukeboxes.", transport: .rest, template: "general/jukeboxes", isBuiltIn: true),
        .init(name: "Jukebox volumes", summary: "Lists the volumes currently associated with one jukebox.", transport: .rest, template: "general/jukeboxes/{jukebox}/volumes", fields: [.init("jukebox", label: "Jukebox ID", placeholder: "Jukebox-1")], isBuiltIn: true),
        .init(
            name: "Is this file archived? — REST",
            summary: "Resolves a client path to its exact P5 ArchiveEntry handle.",
            transport: .rest,
            template: "archive/entries",
            headerTemplates: ["client": "{client}", "path": "{path}", "database": "{index}"],
            fields: [
                .init("client", label: "P5 client", placeholder: "localhost", defaultValue: "localhost"),
                .init("path", label: "File path", placeholder: "/Volumes/Media/example.mov"),
                .init("index", label: "Archive index (optional)", placeholder: "Default-Archive")
            ],
            isBuiltIn: true
        ),
        .init(
            name: "Is this file archived? — nsdchat",
            summary: "The classic handle lookup used by the archive-checker scripts.",
            transport: .nsdchat,
            template: "ArchiveEntry handle {client} \"{{path}}\" {index}",
            fields: [
                .init("client", label: "P5 client", placeholder: "localhost", defaultValue: "localhost"),
                .init("path", label: "File path", placeholder: "/Volumes/Media/example.mov"),
                .init("index", label: "Archive index (optional)", placeholder: "Default-Archive")
            ],
            isBuiltIn: true
        )
    ]
}

public struct ConstructedCommand: Equatable, Sendable {
    public let display: String
    public let executable: String?
    public let arguments: [String]
    public let request: URLRequest?

    public init(display: String, executable: String?, arguments: [String], request: URLRequest?) {
        self.display = display
        self.executable = executable
        self.arguments = arguments
        self.request = request
    }
}

public enum CommandLabError: LocalizedError, Equatable {
    case missingValue(String)
    case invalidPort
    case invalidURL
    case executableMissing(String)
    case processFailed(Int32, String)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .missingValue(let label): return "Enter a value for \(label)."
        case .invalidPort: return "The selected port must be between 1 and 65535."
        case .invalidURL: return "The REST URL could not be constructed."
        case .executableMissing(let path): return "nsdchat was not found at \(path)."
        case .processFailed(let status, let message): return "nsdchat exited with status \(status): \(message)"
        case .invalidResponse: return "The server returned an invalid response."
        }
    }
}

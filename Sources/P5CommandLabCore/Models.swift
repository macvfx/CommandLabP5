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

    public init(
        id: UUID = UUID(),
        name: String,
        summary: String,
        transport: RecipeTransport,
        method: String = "GET",
        template: String,
        headerTemplates: [String: String] = [:],
        fields: [RecipeField] = [],
        isBuiltIn: Bool = false
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
    }

    public var transportLabeledName: String {
        let label = transport == .rest ? "REST" : "nsdchat"
        if name.localizedCaseInsensitiveContains("— \(label)") { return name }
        return "\(name) — \(label)"
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

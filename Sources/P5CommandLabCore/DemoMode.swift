import Foundation

public enum DemoCommandError: LocalizedError, Equatable {
    case unsupportedRecipe(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedRecipe(let name):
            return "No offline demo response is defined for “\(name)”. The command was not run."
        }
    }
}

/// Generates deterministic, fictional presentation output without accepting a URL,
/// executable path, URLRequest, or Process. This API boundary is intentionally unable
/// to contact a P5 server or launch nsdchat.
public enum DemoCommandRunner {
    public static func run(
        recipe: CommandRecipe,
        values: [String: String],
        scenario: DemoScenario
    ) throws -> CommandResult {
        let output: String
        switch recipe.transport {
        case .rest:
            output = try restOutput(recipe: recipe, values: values, scenario: scenario)
        case .nsdchat:
            output = try cliOutput(recipe: recipe, values: values, scenario: scenario)
        }
        let status = recipe.transport == .rest ? "HTTP 200 · SIMULATED" : "Exit 0 · SIMULATED"
        return CommandResult(status: status, output: output)
    }

    private static func restOutput(
        recipe: CommandRecipe,
        values: [String: String],
        scenario: DemoScenario
    ) throws -> String {
        let volume = value("volume", in: values, fallback: "TEST-TAPE-001")
        let jukebox = value("jukebox", in: values, fallback: "TEST-JUKEBOX-01")
        let job = value("job", in: values, fallback: "TEST-JOB-1001")
        let path = value("path", in: values, fallback: "/Volumes/ExampleMedia/Demo.mov")
        let client = value("client", in: values, fallback: "demo-client.example.invalid")
        let mode = scenario == .tapeAttention ? "readonly" : "appendable"
        let jobStatus = scenario == .busyArchive ? "running" : "completed"

        let object: Any
        switch recipe.template.trimmingCharacters(in: CharacterSet(charactersIn: "/")) {
        case "general/srvinfo":
            object = [
                "hostname": "p5-demo.example.invalid",
                "platform": "darwin-arm64",
                "product": "Archiware P5",
                "uptime": scenario == .busyArchive ? 604_812 : 2_678_411,
                "version": "8.0.6"
            ]
        case "general/volumes":
            let all = demoVolumes(scenario: scenario)
            object = recipe.name.localizedCaseInsensitiveContains("Archive volumes")
                ? all.filter { ($0["usage"] as? String) == "Archive" }
                : all
        case "general/volumes/{volume}":
            object = [
                "id": volume, "barcode": "DEMO001L9", "usage": "Archive",
                "mode": mode, "online": scenario != .tapeAttention,
                "location": scenario == .tapeAttention ? "external" : "TEST-JUKEBOX-01",
                "capacityBytes": 18_000_000_000_000 as Int64,
                "freeBytes": scenario == .busyArchive ? 2_100_000_000_000 as Int64 : 11_400_000_000_000 as Int64
            ]
        case "general/volumes/{volume}/jobs":
            object = [["id": job, "type": "archive", "status": jobStatus, "volume": volume]]
        case "general/clients":
            object = [
                ["id": "demo-client.example.invalid", "online": true, "platform": "macOS"],
                ["id": "render-node.example.invalid", "online": scenario != .tapeAttention, "platform": "macOS"]
            ]
        case "general/jobs/{job}":
            object = ["id": job, "status": jobStatus, "type": "archive", "progress": scenario == .busyArchive ? 67 : 100]
        case "general/jobs/{job}/report":
            object = [
                "id": job,
                "status": jobStatus,
                "report": scenario == .busyArchive
                    ? "Archived 67 of 100 fictional files; demo job is still running."
                    : "Archived 100 fictional files with 0 errors."
            ]
        case "archive/indexes":
            object = scenario == .indexDiscovery
                ? [["id": "Example-Archive"], ["id": "Example-Projects"], ["id": "Example-Library"]]
                : [["id": "Example-Archive"]]
        case "archive/plans":
            object = [["id": "Example-Archive-Plan", "enabled": true, "index": "Example-Archive"]]
        case "archive/overview":
            object = [
                "activeJobs": scenario == .busyArchive ? 3 : 0,
                "finishedJobs": scenario == .busyArchive ? 24 : 8,
                "pool": ["name": "Example-Archive-Pool", "usedPercent": scenario == .busyArchive ? 82 : 37]
            ]
        case "general/jukeboxes":
            object = [["id": jukebox, "online": true, "drives": 2, "slots": 24]]
        case "general/jukeboxes/{jukebox}/volumes":
            object = demoVolumes(scenario: scenario).map { $0["id"] as? String ?? "" }
        case "archive/entries":
            object = [[
                "handle": "Example-Archive#DEMO-ENTRY-0001",
                "client": client,
                "path": path,
                "status": "archived"
            ]]
        default:
            throw DemoCommandError.unsupportedRecipe(recipe.name)
        }
        return try json(object)
    }

    private static func cliOutput(
        recipe: CommandRecipe,
        values: [String: String],
        scenario: DemoScenario
    ) throws -> String {
        let volume = value("volume", in: values, fallback: "TEST-TAPE-001")
        let jukebox = value("jukebox", in: values, fallback: "TEST-JUKEBOX-01")
        let job = value("job", in: values, fallback: "TEST-JOB-1001")
        let handle = value("handle", in: values, fallback: "Example-Archive#DEMO-ENTRY-0001")
        let command = recipe.template.lowercased()

        if command == "srvinfo lexxvers" { return "8.0.6" }
        if command == "srvinfo uptime" { return scenario == .busyArchive ? "604812" : "2678411" }
        if command == "volume names" { return demoVolumes(scenario: scenario).compactMap { $0["id"] as? String }.joined(separator: "\n") }
        if command.contains("volume {volume} usage") { return "Archive" }
        if command.contains("volume {volume} mode") { return scenario == .tapeAttention ? "readonly" : "appendable" }
        if command.contains("volume {volume} location") { return scenario == .tapeAttention ? "external" : "TEST-JUKEBOX-01" }
        if command.contains("volume {volume} isonline") { return scenario == .tapeAttention ? "0" : "1" }
        if command.contains("volume {volume} jobs") { return "\(job)" }
        if command == "archiveindex names" {
            return scenario == .indexDiscovery ? "Example-Archive\nExample-Projects\nExample-Library" : "Example-Archive"
        }
        if command == "client names" { return "demo-client.example.invalid\nrender-node.example.invalid" }
        if command.contains("job {job} status") { return scenario == .busyArchive ? "running" : "completed" }
        if command.contains("job {job} report") {
            return scenario == .busyArchive
                ? "Job \(job): archived 67 of 100 fictional files; running"
                : "Job \(job): archived 100 fictional files; 0 errors"
        }
        if command.contains("jukebox {jukebox} volumes") { return "\(jukebox):\nTEST-TAPE-001\nTEST-TAPE-002" }
        if command.contains("archiveentry handle") { return "Example-Archive#DEMO-ENTRY-0001" }
        if command.contains("archiveentry {handle} status") { return "\(handle): archived" }
        _ = volume // The entered value is reflected in the constructed command above the result.
        throw DemoCommandError.unsupportedRecipe(recipe.name)
    }

    private static func value(_ key: String, in values: [String: String], fallback: String) -> String {
        let candidate = values[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return candidate.isEmpty ? fallback : candidate
    }

    private static func demoVolumes(scenario: DemoScenario) -> [[String: Any]] {
        [
            ["id": "TEST-TAPE-001", "usage": "Archive", "mode": scenario == .tapeAttention ? "readonly" : "appendable", "online": true],
            ["id": "TEST-TAPE-002", "usage": "Archive", "mode": "appendable", "online": scenario != .tapeAttention],
            ["id": "TEST-DISK-001", "usage": "Backup", "mode": "appendable", "online": true]
        ]
    }

    private static func json(_ object: Any) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }
}

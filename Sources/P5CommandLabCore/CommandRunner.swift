import Foundation

public struct CommandResult: Sendable {
    public let status: String
    public let output: String

    public init(status: String, output: String) {
        self.status = status
        self.output = output
    }
}

public enum CommandRunner {
    public static func run(_ command: ConstructedCommand, certificatePin: String? = nil) async throws -> CommandResult {
        if let request = command.request {
            let delegate = P5TLSDelegate(pin: certificatePin)
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = request.timeoutInterval
            configuration.timeoutIntervalForResource = request.timeoutInterval
            let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
            defer { session.finishTasksAndInvalidate() }
            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: request)
            } catch {
                throw delegate.failure ?? error
            }
            if let failure = delegate.failure { throw failure }
            guard let http = response as? HTTPURLResponse else { throw CommandLabError.invalidResponse }
            let raw = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
            let output = prettyJSON(data) ?? raw
            return CommandResult(status: "HTTP \(http.statusCode)", output: output)
        }
        guard let executable = command.executable else { throw CommandLabError.invalidResponse }
        return try await runProcess(executable: executable, arguments: command.arguments)
    }

    private static func runProcess(executable: String, arguments: [String]) async throws -> CommandResult {
        guard FileManager.default.isExecutableFile(atPath: executable) else {
            throw CommandLabError.executableMissing(executable)
        }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let stdout = Pipe()
                let stderr = Pipe()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                process.standardOutput = stdout
                process.standardError = stderr
                do {
                    try process.run()
                    process.waitUntilExit()
                    let out = stdout.fileHandleForReading.readDataToEndOfFile()
                    let err = stderr.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: out, encoding: .utf8) ?? ""
                    let error = String(data: err, encoding: .utf8) ?? ""
                    if process.terminationStatus != 0 {
                        continuation.resume(throwing: CommandLabError.processFailed(process.terminationStatus, error.trimmingCharacters(in: .whitespacesAndNewlines)))
                    } else {
                        continuation.resume(returning: CommandResult(status: "Exit 0", output: output.isEmpty ? "(no output)" : output))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func prettyJSON(_ data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else { return nil }
        return String(data: pretty, encoding: .utf8)
    }
}

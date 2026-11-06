import Darwin
import Foundation

public struct CommandResult: Sendable {
    public let status: String
    public let output: String

    public init(status: String, output: String) {
        self.status = status
        self.output = output
    }
}

public struct NsdchatTimeoutPolicy: Equatable, Sendable {
    public var connection: Int
    public var login: Int
    public var command: Int
    public var communication: Int
    public var hardLimit: TimeInterval

    public init(
        connection: Int = 15,
        login: Int = 30,
        command: Int = 300,
        communication: Int = 30,
        hardLimit: TimeInterval = 360
    ) {
        self.connection = max(1, connection)
        self.login = max(1, login)
        self.command = max(1, command)
        self.communication = max(1, communication)
        self.hardLimit = max(0.1, hardLimit)
    }

    public static let `default` = NsdchatTimeoutPolicy()

    fileprivate func applying(to environment: [String: String]) -> [String: String] {
        var result = environment
        result["NSDCHAT_CONN_TOUT"] = String(connection)
        result["NSDCHAT_LOGIN_TOUT"] = String(login)
        result["NSDCHAT_CMD_TOUT"] = String(command)
        result["NSDCHAT_COMM_TOUT"] = String(communication)
        return result
    }
}

public enum CommandRunner {
    public static func run(
        _ command: ConstructedCommand,
        certificatePin: String? = nil,
        cliTimeouts: NsdchatTimeoutPolicy = .default
    ) async throws -> CommandResult {
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
        return try await runProcess(executable: executable, arguments: command.arguments, timeouts: cliTimeouts)
    }

    private static func runProcess(
        executable: String,
        arguments: [String],
        timeouts: NsdchatTimeoutPolicy
    ) async throws -> CommandResult {
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
                process.environment = timeouts.applying(to: ProcessInfo.processInfo.environment)
                process.standardOutput = stdout
                process.standardError = stderr
                do {
                    try process.run()
                    let timeoutLock = NSLock()
                    var didTimeOut = false
                    var didFinish = false
                    let timeout = DispatchWorkItem {
                        timeoutLock.lock()
                        guard !didFinish else {
                            timeoutLock.unlock()
                            return
                        }
                        didTimeOut = true
                        timeoutLock.unlock()
                        guard process.isRunning else { return }
                        let processIdentifier = process.processIdentifier
                        process.terminate()
                        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2) {
                            if process.isRunning { Darwin.kill(processIdentifier, SIGKILL) }
                        }
                    }
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(
                        deadline: .now() + timeouts.hardLimit,
                        execute: timeout
                    )
                    process.waitUntilExit()
                    timeoutLock.lock()
                    didFinish = true
                    let timedOut = didTimeOut
                    timeoutLock.unlock()
                    timeout.cancel()
                    let out = stdout.fileHandleForReading.readDataToEndOfFile()
                    let err = stderr.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: out, encoding: .utf8) ?? ""
                    let error = String(data: err, encoding: .utf8) ?? ""
                    if timedOut {
                        continuation.resume(throwing: CommandLabError.processTimedOut(Int(timeouts.hardLimit.rounded(.up))))
                    } else if process.terminationStatus != 0 {
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

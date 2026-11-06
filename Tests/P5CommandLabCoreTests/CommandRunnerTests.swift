import Foundation
import XCTest
@testable import P5CommandLabCore

final class CommandRunnerTests: XCTestCase {
    func testCLIProcessReceivesBoundedNsdchatTimeouts() async throws {
        let command = ConstructedCommand(
            display: "env",
            executable: "/usr/bin/env",
            arguments: [],
            request: nil
        )
        let policy = NsdchatTimeoutPolicy(
            connection: 11,
            login: 22,
            command: 33,
            communication: 44,
            hardLimit: 5
        )

        let result = try await CommandRunner.run(command, cliTimeouts: policy)

        XCTAssertTrue(result.output.contains("NSDCHAT_CONN_TOUT=11"))
        XCTAssertTrue(result.output.contains("NSDCHAT_LOGIN_TOUT=22"))
        XCTAssertTrue(result.output.contains("NSDCHAT_CMD_TOUT=33"))
        XCTAssertTrue(result.output.contains("NSDCHAT_COMM_TOUT=44"))
    }

    func testCLIProcessIsTerminatedAtHardTimeout() async throws {
        let command = ConstructedCommand(
            display: "sleep",
            executable: "/bin/sleep",
            arguments: ["5"],
            request: nil
        )
        let policy = NsdchatTimeoutPolicy(hardLimit: 0.2)
        let start = Date()

        do {
            _ = try await CommandRunner.run(command, cliTimeouts: policy)
            XCTFail("Expected the CLI process to time out")
        } catch {
            XCTAssertEqual(error as? CommandLabError, .processTimedOut(1))
        }

        XCTAssertLessThan(Date().timeIntervalSince(start), 2)
    }
}

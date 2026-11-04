import XCTest
@testable import P5CommandLabCore

final class CommandBuilderTests: XCTestCase {
    private let profile = ServerProfile(
        host: "p5.example.test",
        restPort: 8000,
        nsdchatPort: 9001,
        username: "demo",
        apiVersion: "v1"
    )

    func testRESTServerInfoBuildsVersionedURLAndRedactsPassword() throws {
        let recipe = try XCTUnwrap(BuiltInRecipes.all.first { $0.name == "Server version & uptime" })
        let command = try CommandBuilder.construct(
            recipe: recipe,
            profile: profile,
            password: "secret",
            values: [:],
            cliConnection: .local,
            revealPassword: false
        )

        XCTAssertEqual(command.request?.url?.absoluteString, "http://p5.example.test:8000/rest/v1/general/srvinfo")
        XCTAssertEqual(command.request?.httpMethod, "GET")
        XCTAssertTrue(command.display.contains("demo:••••••"))
        XCTAssertFalse(command.display.contains("secret"))
    }

    func testRemoteCLIAddsAwsockWhileLocalDoesNot() throws {
        let recipe = try XCTUnwrap(BuiltInRecipes.all.first { $0.name == "Volumes — nsdchat" })
        let local = try CommandBuilder.construct(recipe: recipe, profile: profile, password: "secret", values: [:], cliConnection: .local, revealPassword: false)
        let remote = try CommandBuilder.construct(recipe: recipe, profile: profile, password: "secret", values: [:], cliConnection: .remote, revealPassword: false)

        XCTAssertEqual(local.arguments, ["-c", "Volume", "names"])
        XCTAssertEqual(remote.arguments, ["-s", "awsock:/demo:secret@p5.example.test:9001", "-c", "Volume", "names"])
        XCTAssertFalse(remote.display.contains("secret"))
        XCTAssertTrue(remote.display.contains("awsock:/demo:••••••@p5.example.test:9001"))
    }

    func testLocalAWFileServerInfoCommandsMatchP5CLIForm() throws {
        let versionRecipe = try XCTUnwrap(BuiltInRecipes.all.first { $0.name == "Server version — nsdchat" })
        let uptimeRecipe = try XCTUnwrap(BuiltInRecipes.all.first { $0.name == "Server uptime — nsdchat" })
        let version = try CommandBuilder.construct(recipe: versionRecipe, profile: profile, password: "", values: [:], cliConnection: .localAWFile, revealPassword: false)
        let uptime = try CommandBuilder.construct(recipe: uptimeRecipe, profile: profile, password: "", values: [:], cliConnection: .localAWFile, revealPassword: false)

        XCTAssertEqual(version.arguments, ["-s", "awfile://usr/local/aw:lexxsrv", "-c", "srvinfo", "lexxvers"])
        XCTAssertEqual(uptime.arguments, ["-s", "awfile://usr/local/aw:lexxsrv", "-c", "srvinfo", "uptime"])
        XCTAssertTrue(version.display.contains("srvinfo lexxvers"))
        XCTAssertTrue(uptime.display.contains("srvinfo uptime"))
    }

    func testCustomAWFileConnectionIsUsed() throws {
        var customProfile = profile
        customProfile.awfileConnection = "awfile://opt/aw:lexxsrv"
        let recipe = try XCTUnwrap(BuiltInRecipes.all.first { $0.name == "Server uptime — nsdchat" })
        let command = try CommandBuilder.construct(recipe: recipe, profile: customProfile, password: "", values: [:], cliConnection: .localAWFile, revealPassword: false)

        XCTAssertEqual(command.arguments.prefix(2), ["-s", "awfile://opt/aw:lexxsrv"])
    }

    func testRESTArchiveLookupUsesHeaders() throws {
        let recipe = try XCTUnwrap(BuiltInRecipes.all.first { $0.name == "Is this file archived? — REST" })
        let command = try CommandBuilder.construct(
            recipe: recipe,
            profile: profile,
            password: "secret",
            values: ["client": "localhost", "path": "/Volumes/Media/A File.mov", "index": "Default-Archive"],
            cliConnection: .local,
            revealPassword: false
        )

        XCTAssertEqual(command.request?.value(forHTTPHeaderField: "client"), "localhost")
        XCTAssertEqual(command.request?.value(forHTTPHeaderField: "path"), "/Volumes/Media/A File.mov")
        XCTAssertEqual(command.request?.value(forHTTPHeaderField: "database"), "Default-Archive")
    }

    func testNsdchatArchiveLookupKeepsBraceWrappedPathAsOneArgument() throws {
        let recipe = try XCTUnwrap(BuiltInRecipes.all.first { $0.name == "Is this file archived? — nsdchat" })
        let command = try CommandBuilder.construct(
            recipe: recipe,
            profile: profile,
            password: "secret",
            values: ["client": "localhost", "path": "/Volumes/Media/A File.mov", "index": "Default-Archive"],
            cliConnection: .local,
            revealPassword: false
        )

        XCTAssertEqual(command.arguments, ["-c", "ArchiveEntry", "handle", "localhost", "{/Volumes/Media/A File.mov}", "Default-Archive"])
    }

    func testRequiredFieldFailsClearly() throws {
        let recipe = try XCTUnwrap(BuiltInRecipes.all.first { $0.name == "Volume usage" })
        XCTAssertThrowsError(try CommandBuilder.construct(recipe: recipe, profile: profile, password: "", values: [:], cliConnection: .local, revealPassword: false)) { error in
            XCTAssertEqual(error as? CommandLabError, .missingValue("Volume ID"))
        }
    }

    func testEveryRecipeNameHasAnUnambiguousTransportLabel() {
        for recipe in BuiltInRecipes.all {
            let expected = recipe.transport == .rest ? "REST" : "nsdchat"
            XCTAssertTrue(recipe.transportLabeledName.localizedCaseInsensitiveContains(expected), recipe.name)
        }
        let custom = CommandRecipe(name: "My command", summary: "", transport: .rest, template: "general/jobs")
        XCTAssertEqual(custom.transportLabeledName, "My command — REST")
    }

    func testCertificatePinIsBoundToHostAndRESTPort() {
        var secured = profile
        secured.useHTTPS = true
        secured.trustCertificate(String(repeating: "AA", count: 32))

        XCTAssertNotNil(secured.certificatePinForCurrentEndpoint)
        secured.restPort += 1
        XCTAssertFalse(secured.certificatePinMatchesEndpoint)
        XCTAssertNil(secured.certificatePinForCurrentEndpoint)
    }

    func testFingerprintComparisonAcceptsCommonFormatting() {
        let compact = String(repeating: "A1", count: 32)
        let colonSeparated = stride(from: 0, to: compact.count, by: 2).map { offset -> String in
            let start = compact.index(compact.startIndex, offsetBy: offset)
            let end = compact.index(start, offsetBy: 2)
            return String(compact[start..<end])
        }.joined(separator: ":")

        XCTAssertTrue(P5TLSFailure.fingerprintsMatch("SHA256 Fingerprint=\(colonSeparated)", compact.lowercased()))
        XCTAssertFalse(P5TLSFailure.fingerprintsMatch(compact, String(repeating: "B2", count: 32)))
    }

    func testForgettingCertificateRestoresSystemTrust() {
        var secured = profile
        secured.useHTTPS = true
        secured.trustCertificate(String(repeating: "AB", count: 32))
        secured.useSystemCertificateTrust()

        XCTAssertFalse(secured.hasPinnedCertificate)
        XCTAssertNil(secured.certificatePinForCurrentEndpoint)
    }

    func testDisposableTLSCertificatePinAndMismatchWhenConfigured() async throws {
        guard let urlText = ProcessInfo.processInfo.environment["P5_COMMAND_LAB_TEST_TLS_URL"],
              let url = URL(string: urlText),
              let pin = ProcessInfo.processInfo.environment["P5_COMMAND_LAB_TEST_TLS_PIN"] else {
            throw XCTSkip("Set the disposable TLS URL and fingerprint to run the live pinning check.")
        }
        let request = URLRequest(url: url)
        let command = ConstructedCommand(display: "disposable TLS test", executable: nil, arguments: [], request: request)

        let accepted = try await CommandRunner.run(command, certificatePin: pin)
        XCTAssertEqual(accepted.status, "HTTP 200")

        do {
            _ = try await CommandRunner.run(command, certificatePin: String(repeating: "00", count: 32))
            XCTFail("A changed certificate must not be accepted.")
        } catch let error as P5TLSFailure {
            guard case .certificateChanged = error else {
                return XCTFail("Expected a changed-certificate error, got \(error).")
            }
        }
    }
}

import XCTest
@testable import P5CommandLabCore

final class DemoModeTests: XCTestCase {
    private let values = [
        "volume": "TEST-TAPE-001",
        "jukebox": "TEST-JUKEBOX-01",
        "job": "TEST-JOB-1001",
        "client": "demo-client.example.invalid",
        "path": "/Volumes/ExampleMedia/Demo.mov",
        "index": "Example-Archive",
        "handle": "Example-Archive#DEMO-ENTRY-0001"
    ]

    func testLegacyProfileDecodesWithDemoModeDisabled() throws {
        let legacy: [String: Any] = [
            "id": UUID().uuidString,
            "name": "Existing Server",
            "host": "p5.example.invalid",
            "restPort": 8000,
            "nsdchatPort": 9001,
            "username": "operator",
            "apiVersion": "v1",
            "useHTTPS": false,
            "nsdchatPath": "/usr/local/aw/bin/nsdchat"
        ]
        let data = try JSONSerialization.data(withJSONObject: legacy)
        let decoded = try JSONDecoder().decode(ServerProfile.self, from: data)

        XCTAssertFalse(decoded.isDemoMode)
        XCTAssertEqual(decoded.demoScenario, .healthyLibrary)
    }

    func testDemoProfileRoundTrips() throws {
        var profile = ServerProfile.offlineDemo
        profile.demoScenario = .tapeAttention
        let decoded = try JSONDecoder().decode(ServerProfile.self, from: JSONEncoder().encode(profile))

        XCTAssertEqual(decoded, profile)
        XCTAssertTrue(decoded.isDemoMode)
        XCTAssertEqual(decoded.demoScenario, .tapeAttention)
    }

    func testFictionalCommandProfileNeverUsesLiveProfileAddressOrCredentials() {
        var profile = ServerProfile.offlineDemo
        profile.host = "192.0.2.55"
        profile.username = "someone"
        let fictional = profile.commandProfile

        XCTAssertEqual(fictional.host, "p5-demo.example.invalid")
        XCTAssertEqual(fictional.username, "demo-operator")
        XCTAssertTrue(fictional.host.hasSuffix(".invalid"))
    }

    func testEveryBuiltInRecipeHasAResponseForEveryScenario() throws {
        for scenario in DemoScenario.allCases {
            for recipe in BuiltInRecipes.all {
                let result = try DemoCommandRunner.run(recipe: recipe, values: values, scenario: scenario)
                XCTAssertTrue(result.status.contains("SIMULATED"), "\(scenario): \(recipe.name)")
                XCTAssertFalse(result.output.isEmpty, "\(scenario): \(recipe.name)")
            }
        }
    }

    func testComparisonPackHasAResponseForEveryScenario() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("CommandPacks/P5-Read-Only-Comparisons.json")
        let pack = try CommandPackLoader.decode(Data(contentsOf: url))

        for scenario in DemoScenario.allCases {
            for recipe in pack.recipes {
                XCTAssertNoThrow(try DemoCommandRunner.run(recipe: recipe, values: values, scenario: scenario), "\(scenario): \(recipe.name)")
            }
        }
    }

    func testUnknownRecipeFailsWithoutPretendingItRan() {
        let recipe = CommandRecipe(name: "Unknown", summary: "", transport: .rest, template: "general/not-a-demo-route")

        XCTAssertThrowsError(try DemoCommandRunner.run(recipe: recipe, values: [:], scenario: .healthyLibrary)) { error in
            XCTAssertEqual(error as? DemoCommandError, .unsupportedRecipe("Unknown"))
            XCTAssertTrue(error.localizedDescription.contains("not run"))
        }
    }
}

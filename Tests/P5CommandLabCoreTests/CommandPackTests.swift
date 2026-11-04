import XCTest
@testable import P5CommandLabCore

final class CommandPackTests: XCTestCase {
    func testValidReadOnlyPackIsAttributedAndAccepted() throws {
        let pack = try CommandPackLoader.validate(makePack())
        XCTAssertEqual(pack.recipes.first?.packID, pack.id)
        XCTAssertEqual(pack.recipes.first?.effectiveEffect, .readOnly)
        XCTAssertFalse(try XCTUnwrap(pack.recipes.first).isBuiltIn)
    }

    func testRejectsUnsupportedSchema() {
        var pack = makePack()
        pack.schemaVersion = 2
        XCTAssertThrowsError(try CommandPackLoader.validate(pack)) { error in
            XCTAssertEqual(error as? CommandPackError, .unsupportedSchema(2))
        }
    }

    func testRejectsMutatingCommand() {
        var pack = makePack()
        pack.recipes[0].effect = .mutating
        XCTAssertThrowsError(try CommandPackLoader.validate(pack)) { error in
            XCTAssertEqual(error as? CommandPackError, .unsafeRecipe("Volumes", .mutating))
        }
    }

    func testRejectsNonGETRESTCommand() {
        var pack = makePack()
        pack.recipes[0].method = "PUT"
        XCTAssertThrowsError(try CommandPackLoader.validate(pack)) { error in
            XCTAssertEqual(error as? CommandPackError, .nonGETRESTRecipe("Volumes"))
        }
    }

    func testRejectsReservedAuthenticationHeader() {
        var pack = makePack()
        pack.recipes[0].headerTemplates["Authorization"] = "Bearer example"
        XCTAssertThrowsError(try CommandPackLoader.validate(pack))
    }

    func testRejectsUnknownPlaceholder() {
        var pack = makePack()
        pack.recipes[0].template = "general/volumes/{missing}"
        XCTAssertThrowsError(try CommandPackLoader.validate(pack))
    }

    func testRepositoryExamplePackDecodes() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("CommandPacks/P5-Read-Only-Comparisons.json")
        let pack = try CommandPackLoader.decode(Data(contentsOf: url))
        XCTAssertEqual(pack.recipes.count, 14)
        XCTAssertTrue(pack.recipes.allSatisfy { $0.effectiveEffect == .readOnly })
        XCTAssertEqual(Set(pack.recipes.compactMap(\.packID)), [pack.id])
    }

    private func makePack() -> CommandPack {
        CommandPack(
            id: "ca.example.read-only",
            title: "Example Read-only",
            version: "1.0.0",
            summary: "Test pack",
            sources: [.init(title: "Example", url: "https://example.invalid/reference")],
            recipes: [
                .init(
                    name: "Volumes",
                    summary: "Lists volumes",
                    transport: .rest,
                    template: "general/volumes/{volume}",
                    fields: [.init("volume", label: "Volume", placeholder: "TEST-VOLUME")],
                    effect: .readOnly
                )
            ]
        )
    }
}

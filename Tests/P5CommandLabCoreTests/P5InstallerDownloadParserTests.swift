import XCTest
@testable import P5CommandLabCore

final class P5InstallerDownloadParserTests: XCTestCase {
    private let downloadPage = URL(string: "https://www.archiware.com/download-p5/")!

    func testFindsCurrentMacInstallerWithHTMLEscapedQuery() throws {
        let html = #"<h2>Archiware P5 Version 8.0.6</h2><a href="/?awdl=awpst806-darwin.dmg&amp;awpf=mac">New Install</a>"#
        let result = try XCTUnwrap(P5InstallerDownloadParser.latestMacInstaller(in: html, downloadPage: downloadPage))

        XCTAssertEqual(result.filename, "awpst806-darwin.dmg")
        XCTAssertEqual(result.versionCode, 806)
        XCTAssertEqual(result.displayVersion, "8.0.6")
        XCTAssertEqual(result.url.absoluteString, "https://www.archiware.com/?awdl=awpst806-darwin.dmg&awpf=mac")
    }

    func testFindsLiveWordPressNumericEntityEncoding() throws {
        let html = #"<a href="/?awdl=awpst806-darwin.dmg&#038;awpf=mac" target="_blank">New Install</a>"#
        let result = try XCTUnwrap(P5InstallerDownloadParser.latestMacInstaller(in: html, downloadPage: downloadPage))

        XCTAssertEqual(result.filename, "awpst806-darwin.dmg")
        XCTAssertEqual(result.url.absoluteString, "https://www.archiware.com/?awdl=awpst806-darwin.dmg&awpf=mac")
    }

    func testSelectsHighestVersionAndIgnoresOtherPlatforms() throws {
        let html = """
        <a href="/?awdl=awpst804-darwin.dmg&awpf=mac">Older Mac</a>
        <a href="/?awdl=awpst806-linux.tgz&awpf=linux">Linux</a>
        <a href="/?awdl=awpst806-darwin.dmg&awpf=mac">Current Mac</a>
        """
        let result = try XCTUnwrap(P5InstallerDownloadParser.latestMacInstaller(in: html, downloadPage: downloadPage))

        XCTAssertEqual(result.filename, "awpst806-darwin.dmg")
    }

    func testRejectsMatchingQueryOnAnotherHost() {
        let html = #"<a href="https://downloads.example.invalid/?awdl=awpst999-darwin.dmg&amp;awpf=mac">Not official</a>"#

        XCTAssertNil(P5InstallerDownloadParser.latestMacInstaller(in: html, downloadPage: downloadPage))
    }

    func testRejectsNonHTTPSDownloadPage() {
        let insecurePage = URL(string: "http://www.archiware.com/download-p5/")!
        let html = #"<a href="/?awdl=awpst806-darwin.dmg&amp;awpf=mac">New Install</a>"#

        XCTAssertNil(P5InstallerDownloadParser.latestMacInstaller(in: html, downloadPage: insecurePage))
    }
}

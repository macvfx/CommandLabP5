import Foundation

public struct P5InstallerDownload: Equatable, Sendable {
    public let url: URL
    public let filename: String
    public let versionCode: Int
    public let displayVersion: String?

    public init(url: URL, filename: String, versionCode: Int, displayVersion: String? = nil) {
        self.url = url
        self.filename = filename
        self.versionCode = versionCode
        self.displayVersion = displayVersion
    }
}

public enum P5InstallerDownloadParser {
    public static func latestMacInstaller(
        in html: String,
        downloadPage: URL
    ) -> P5InstallerDownload? {
        guard downloadPage.scheme?.lowercased() == "https",
              let trustedHost = downloadPage.host?.lowercased(),
              let expression = try? NSRegularExpression(
                pattern: #"href\s*=\s*[\"']([^\"']+)[\"']"#,
                options: [.caseInsensitive]
              ) else {
            return nil
        }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let displayVersion = releaseVersion(in: html)
        let candidates = expression.matches(in: html, range: range).compactMap { match -> P5InstallerDownload? in
            guard let hrefRange = Range(match.range(at: 1), in: html) else { return nil }
            let href = decodeAmpersands(in: String(html[hrefRange]))

            guard let url = URL(string: href, relativeTo: downloadPage)?.absoluteURL,
                  url.scheme?.lowercased() == "https",
                  url.host?.lowercased() == trustedHost,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let items = components.queryItems ?? []
            guard items.first(where: { $0.name.caseInsensitiveCompare("awpf") == .orderedSame })?.value?.lowercased() == "mac",
                  let filename = items.first(where: { $0.name.caseInsensitiveCompare("awdl") == .orderedSame })?.value,
                  let versionCode = versionCode(from: filename) else {
                return nil
            }

            return P5InstallerDownload(
                url: url,
                filename: filename,
                versionCode: versionCode,
                displayVersion: displayVersion
            )
        }

        return candidates.max { lhs, rhs in lhs.versionCode < rhs.versionCode }
    }

    private static func decodeAmpersands(in text: String) -> String {
        ["&amp;", "&#038;", "&#38;", "&#x26;"].reduce(text) { result, entity in
            result.replacingOccurrences(of: entity, with: "&", options: .caseInsensitive)
        }
    }

    private static func releaseVersion(in html: String) -> String? {
        guard let expression = try? NSRegularExpression(
            pattern: #"P5\s+Version\s+([0-9]+(?:\.[0-9]+){1,2})"#,
            options: [.caseInsensitive]
        ) else {
            return nil
        }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = expression.firstMatch(in: html, range: range),
              let versionRange = Range(match.range(at: 1), in: html) else {
            return nil
        }
        return String(html[versionRange])
    }

    private static func versionCode(from filename: String) -> Int? {
        guard let expression = try? NSRegularExpression(
            pattern: #"^awpst([0-9]+)-darwin\.dmg$"#,
            options: [.caseInsensitive]
        ) else {
            return nil
        }
        let range = NSRange(filename.startIndex..<filename.endIndex, in: filename)
        guard let match = expression.firstMatch(in: filename, range: range),
              let versionRange = Range(match.range(at: 1), in: filename) else {
            return nil
        }
        return Int(filename[versionRange])
    }
}

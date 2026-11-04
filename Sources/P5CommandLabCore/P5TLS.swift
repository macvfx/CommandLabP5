import CryptoKit
import Foundation
import Security

public struct P5CertificateInfo: Equatable, Sendable {
    public let sha256: String
    public let subjectSummary: String
    public let isTrustedBySystem: Bool

    public init(sha256: String, subjectSummary: String, isTrustedBySystem: Bool) {
        self.sha256 = sha256
        self.subjectSummary = subjectSummary
        self.isTrustedBySystem = isTrustedBySystem
    }
}

public enum P5TLSFailure: Error, LocalizedError, Equatable, Sendable {
    case certificateChanged(expected: String, presented: String)
    case redirectRefused
    case pinBelongsToAnotherEndpoint

    public var errorDescription: String? {
        switch self {
        case .certificateChanged(let expected, let presented):
            return "The server certificate changed. Connection refused (trusted \(Self.short(expected)), presented \(Self.short(presented))). Review the certificate before trusting the replacement."
        case .redirectRefused:
            return "The server redirected the REST request. The redirect was refused to protect credentials; configure the intended P5 endpoint directly."
        case .pinBelongsToAnotherEndpoint:
            return "The saved certificate belongs to a different host or REST port. Save the profile, then check and trust the certificate for this endpoint."
        }
    }

    public static func short(_ fingerprint: String) -> String {
        let bytes = normalize(fingerprint)
        guard bytes.count >= 8 else { return fingerprint }
        return stride(from: 0, to: 8, by: 2)
            .map { index in
                let start = bytes.index(bytes.startIndex, offsetBy: index)
                let end = bytes.index(start, offsetBy: 2)
                return String(bytes[start..<end])
            }
            .joined(separator: ":") + "…"
    }

    public static func fingerprintsMatch(_ lhs: String, _ rhs: String) -> Bool {
        let a = Array(normalize(lhs).utf8)
        let b = Array(normalize(rhs).utf8)
        guard a.count == 64, a.count == b.count else { return false }
        var difference: UInt8 = 0
        for (x, y) in zip(a, b) { difference |= x ^ y }
        return difference == 0
    }

    private static func normalize(_ value: String) -> String {
        var text = Substring(value)
        if let equals = text.lastIndex(of: "=") {
            text = text[text.index(after: equals)...]
        } else if let label = text.range(of: ": ") {
            text = text[label.upperBound...]
        }
        return text.uppercased().filter(\.isHexDigit)
    }
}

public enum P5TLSProbe {
    public static func certificateInfo(host: String, port: Int, timeout: TimeInterval = 15) async -> P5CertificateInfo? {
        guard (1...65535).contains(port) else { return nil }
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.port = port
        components.path = "/"
        guard let url = components.url else { return nil }

        let collector = CertificateCollector()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration, delegate: collector, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        _ = try? await session.data(from: url)
        return collector.info
    }
}

final class P5TLSDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let pin: String?
    private let lock = NSLock()
    private var storedFailure: P5TLSFailure?

    init(pin: String?) {
        self.pin = pin
    }

    var failure: P5TLSFailure? {
        lock.lock()
        defer { lock.unlock() }
        return storedFailure
    }

    private func fail(_ failure: P5TLSFailure) {
        lock.lock()
        storedFailure = failure
        lock.unlock()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        guard let pin else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        guard let presented = Self.leafFingerprint(of: serverTrust),
              P5TLSFailure.fingerprintsMatch(pin, presented) else {
            fail(.certificateChanged(expected: pin, presented: Self.leafFingerprint(of: serverTrust) ?? "unavailable"))
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        fail(.redirectRefused)
        completionHandler(nil)
    }

    fileprivate static func leafFingerprint(of trust: SecTrust) -> String? {
        guard let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let leaf = chain.first else { return nil }
        return SHA256.hash(data: SecCertificateCopyData(leaf) as Data)
            .map { String(format: "%02X", $0) }
            .joined(separator: ":")
    }
}

private final class CertificateCollector: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var storedInfo: P5CertificateInfo?

    var info: P5CertificateInfo? {
        lock.lock()
        defer { lock.unlock() }
        return storedInfo
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let trust = challenge.protectionSpace.serverTrust,
              let fingerprint = P5TLSDelegate.leafFingerprint(of: trust) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        var trustError: CFError?
        let trusted = SecTrustEvaluateWithError(trust, &trustError)
        let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate]
        let subject = chain?.first.flatMap { SecCertificateCopySubjectSummary($0) as String? } ?? ""
        lock.lock()
        storedInfo = P5CertificateInfo(sha256: fingerprint, subjectSummary: subject, isTrustedBySystem: trusted)
        lock.unlock()
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}

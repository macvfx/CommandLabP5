import SwiftUI
import P5CommandLabCore

private enum CertificateCheckState: Equatable {
    case checking
    case found(P5CertificateInfo)
    case unreachable(String)
}

struct CertificateTrustSheet: View {
    let host: String
    let port: Int
    let existingPin: String
    let onTrust: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var state: CertificateCheckState = .checking

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Certificate for \(host):\(port)")
                .font(.headline)

            switch state {
            case .checking:
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("Asking the server for its certificate…")
                        .foregroundStyle(.secondary)
                }
            case .unreachable(let reason):
                Label(reason, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                Text("The server may not have TLS enabled on this REST port.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .found(let info):
                certificateDetails(info)
            }

            Spacer(minLength: 0)
            HStack {
                if case .unreachable = state {
                    Button("Try Again") { Task { await check() } }
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                if case .found(let info) = state {
                    Button(buttonTitle(for: info)) {
                        onTrust(info.isTrustedBySystem ? "" : info.sha256)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(20)
        .frame(width: 570, height: 450)
        .task { await check() }
    }

    @ViewBuilder
    private func certificateDetails(_ info: P5CertificateInfo) -> some View {
        if info.isTrustedBySystem {
            Label("macOS already trusts this certificate", systemImage: "checkmark.seal")
                .foregroundStyle(.green)
            Text("No pin is needed. Use macOS Trust so a normally renewed certificate continues to work.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Label("macOS does not trust this certificate", systemImage: "exclamationmark.shield")
                .foregroundStyle(.orange)
            Text("Compare this fingerprint with one obtained through a trusted channel. Trusting it saves this exact certificate for this server; a changed certificate will be refused.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                LabeledContent("Subject") {
                    Text(info.subjectSummary.isEmpty ? "—" : info.subjectSummary)
                        .textSelection(.enabled)
                }
                LabeledContent("SHA-256") {
                    Text(info.sha256)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(4)
        }

        if !existingPin.isEmpty {
            if P5TLSFailure.fingerprintsMatch(existingPin, info.sha256) {
                Label("This is the certificate already trusted for this endpoint", systemImage: "checkmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Label("This is not the certificate trusted before. Continue only after confirming why it changed.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func buttonTitle(for info: P5CertificateInfo) -> String {
        if info.isTrustedBySystem { return "Use macOS Trust" }
        if !existingPin.isEmpty && !P5TLSFailure.fingerprintsMatch(existingPin, info.sha256) {
            return "Trust the New Certificate"
        }
        return "Trust This Certificate"
    }

    private func check() async {
        state = .checking
        if let info = await P5TLSProbe.certificateInfo(host: host, port: port) {
            guard !Task.isCancelled else { return }
            state = .found(info)
        } else {
            state = .unreachable("\(host) did not answer on port \(port), or did not offer TLS.")
        }
    }
}

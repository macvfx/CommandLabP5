import AppKit
import SwiftUI

struct TerminalOutputView: NSViewRepresentable {
    let text: String
    var focusNewest: Bool = true

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(calibratedRed: 0.018, green: 0.035, blue: 0.045, alpha: 1)

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.backgroundColor = scrollView.backgroundColor
        textView.textContainerInset = NSSize(width: 14, height: 12)
        textView.textContainer?.widthTracksTextView = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        scrollView.documentView = textView
        render(text, focusNewest: focusNewest, in: textView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        let textChanged = textView.string != text
        render(text, focusNewest: focusNewest, in: textView)
        if textChanged { textView.scrollToEndOfDocument(nil) }
    }

    private func render(_ source: String, focusNewest: Bool, in textView: NSTextView) {
        let amber = NSColor(calibratedRed: 1.0, green: 0.67, blue: 0.12, alpha: 1)
        let cyan = NSColor(calibratedRed: 0.24, green: 0.87, blue: 0.95, alpha: 1)
        let green = NSColor(calibratedRed: 0.48, green: 0.92, blue: 0.55, alpha: 1)
        let magenta = NSColor(calibratedRed: 0.94, green: 0.49, blue: 0.92, alpha: 1)
        let red = NSColor(calibratedRed: 1.0, green: 0.35, blue: 0.30, alpha: 1)
        let muted = NSColor(calibratedWhite: 0.58, alpha: 1)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        let fullShadow = NSShadow()
        fullShadow.shadowColor = amber.withAlphaComponent(0.38)
        fullShadow.shadowBlurRadius = 3
        fullShadow.shadowOffset = .zero
        let baseAmber = focusNewest ? amber.withAlphaComponent(0.30) : amber

        let attributed = NSMutableAttributedString(
            string: source,
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 13.5, weight: .medium),
                .foregroundColor: baseAmber,
                .paragraphStyle: paragraph
            ]
        )
        let full = NSRange(location: 0, length: attributed.length)
        let latest = focusNewest ? latestBlockRange(in: source) : full

        applySyntax(to: attributed, range: full, cyan: cyan.withAlphaComponent(focusNewest ? 0.30 : 1), green: green.withAlphaComponent(focusNewest ? 0.30 : 1), magenta: magenta.withAlphaComponent(focusNewest ? 0.30 : 1), red: red.withAlphaComponent(focusNewest ? 0.36 : 1), muted: muted.withAlphaComponent(focusNewest ? 0.42 : 1))

        if focusNewest, latest.length > 0 {
            attributed.addAttributes([
                .foregroundColor: amber,
                .backgroundColor: amber.withAlphaComponent(0.055),
                .shadow: fullShadow
            ], range: latest)
            applySyntax(to: attributed, range: latest, cyan: cyan, green: green, magenta: magenta, red: red, muted: muted)
        } else if full.length > 0 {
            attributed.addAttribute(.shadow, value: fullShadow, range: full)
        }

        textView.textStorage?.setAttributedString(attributed)
    }

    private func applySyntax(
        to attributed: NSMutableAttributedString,
        range: NSRange,
        cyan: NSColor,
        green: NSColor,
        magenta: NSColor,
        red: NSColor,
        muted: NSColor
    ) {
        apply(#"\[[^\]\n]+\]"#, color: muted, to: attributed, range: range)
        apply(#"\bCOMMAND\b|\bRESULT\b|\bHTTP [1-3][0-9]{2}\b|\bExit 0\b"#, color: cyan, to: attributed, range: range, bold: true)
        apply(#"\bERROR\b|\bHTTP [45][0-9]{2}\b"#, color: red, to: attributed, range: range, bold: true)
        // jq-inspired JSON: values first, then keys so key colouring wins.
        apply(#"\"(?:\\.|[^\"\\])*\""#, color: green, to: attributed, range: range)
        apply(#"\"(?:\\.|[^\"\\])*\"(?=\s*:)"#, color: cyan, to: attributed, range: range, bold: true)
        apply(#"(?<![A-Za-z0-9_])-?\b\d+(?:\.\d+)?\b"#, color: magenta, to: attributed, range: range)
        apply(#"\b(?:true|false|null)\b"#, color: magenta, to: attributed, range: range, bold: true)
    }

    private func latestBlockRange(in source: String) -> NSRange {
        let full = NSRange(source.startIndex..<source.endIndex, in: source)
        guard let regex = try? NSRegularExpression(pattern: #"(?m)^\[[^\]\n]+\]"#),
              let match = regex.matches(in: source, range: full).last else {
            return full
        }
        return NSRange(location: match.range.location, length: full.length - match.range.location)
    }

    private func apply(
        _ pattern: String,
        color: NSColor,
        to string: NSMutableAttributedString,
        range: NSRange,
        bold: Bool = false
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        for match in regex.matches(in: string.string, range: range) {
            string.addAttribute(.foregroundColor, value: color, range: match.range)
            if bold {
                string.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13.5, weight: .bold), range: match.range)
            }
        }
    }
}

struct LabGroupBoxStyle: GroupBoxStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accent)
                    .frame(width: 4, height: 18)
                    .shadow(color: accent.opacity(0.7), radius: 4)
                configuration.label
                    .font(.headline)
                Spacer()
            }
            configuration.content
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.075), accent.opacity(0.055)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accent.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 9, y: 4)
    }
}

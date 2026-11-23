import Foundation

/// Pulls TeX out of Markdown before parsing, so the Markdown parser can't mangle it
/// (`a_1 b_2` turning into emphasis, `\\` into `\`), then puts it back as
/// `<span class="math">` elements that the page renders with MathJax.
///
/// Recognised: `$…$`, `$$…$$`, `\(…\)`, `\[…\]`. Code spans and fenced code blocks are
/// left alone. Inline `$` follows Pandoc's rules so prices like "$5 and $10" stay text:
/// the opening `$` must not be followed by a space, the closing one must not be preceded
/// by a space or followed by a digit. Write `\$` for a literal dollar sign.
enum MathExtractor {
    struct Formula {
        let tex: String
        let display: Bool
    }

    static func token(_ i: Int) -> String { "FOLIOMATH\(i)X" }

    static func extract(_ markdown: String) -> (markdown: String, formulas: [Formula]) {
        guard markdown.contains("$") || markdown.contains("\\(") || markdown.contains("\\[") else {
            return (markdown, [])
        }
        var formulas: [Formula] = []
        var output: [String] = []
        var chunk: [Substring] = []
        var fence: Substring?     // the open ``` / ~~~ run, if inside a fenced code block

        func flush() {
            if !chunk.isEmpty { output.append(scan(chunk.joined(separator: "\n"), &formulas)); chunk = [] }
        }

        for line in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.drop { $0 == " " }
            let indent = line.count - trimmed.count
            if let open = fence {
                output.append(String(line))
                if indent <= 3, trimmed.hasPrefix(open), trimmed.drop(while: { $0 == open.first }).allSatisfy(\.isWhitespace) {
                    fence = nil
                }
            } else if indent <= 3, let marker = trimmed.first, marker == "`" || marker == "~" {
                let run = trimmed.prefix { $0 == marker }
                if run.count >= 3 {
                    flush()
                    fence = run
                    output.append(String(line))
                } else {
                    chunk.append(line)
                }
            } else {
                chunk.append(line)
            }
        }
        flush()
        return (output.joined(separator: "\n"), formulas)
    }

    /// Scans text outside fenced code for math, skipping inline code spans.
    private static func scan(_ text: String, _ formulas: inout [Formula]) -> String {
        let c = Array(text)
        var out = ""
        var i = 0

        func emitMath(_ tex: [Character], display: Bool) {
            formulas.append(Formula(tex: String(tex).trimmingCharacters(in: .whitespacesAndNewlines), display: display))
            out += token(formulas.count - 1)
        }
        /// Index of `pattern` at or after `from`, or nil.
        func find(_ pattern: [Character], from: Int) -> Int? {
            guard pattern.count <= c.count else { return nil }
            var j = from
            while j + pattern.count <= c.count {
                if c[j] == "\\" && pattern.first != "\\" { j += 2; continue }   // skip escaped chars inside TeX
                if Array(c[j..<j + pattern.count]) == pattern { return j }
                j += 1
            }
            return nil
        }

        while i < c.count {
            let ch = c[i]
            let next: Character? = i + 1 < c.count ? c[i + 1] : nil

            if ch == "\\", let next {
                if next == "(" || next == "[" {
                    let close: [Character] = next == "(" ? ["\\", ")"] : ["\\", "]"]
                    if let end = find(close, from: i + 2) {
                        emitMath(Array(c[(i + 2)..<end]), display: next == "[")
                        i = end + 2
                        continue
                    }
                }
                out.append(ch); out.append(next)          // keep other escapes (incl. \$) as-is
                i += 2
                continue
            }

            if ch == "`" {                                  // inline code span: copy verbatim
                var n = 0
                while i + n < c.count && c[i + n] == "`" { n += 1 }
                var j = i + n
                var closeAt: Int?
                while j < c.count {
                    if c[j] == "`" {
                        var m = 0
                        while j + m < c.count && c[j + m] == "`" { m += 1 }
                        if m == n { closeAt = j; break }
                        j += m
                    } else { j += 1 }
                }
                let end = closeAt.map { $0 + n } ?? (i + n)
                out += String(c[i..<end])
                i = end
                continue
            }

            if ch == "$" {
                if next == "$" {                            // $$ display $$
                    if let end = find(["$", "$"], from: i + 2), end > i + 2 {
                        emitMath(Array(c[(i + 2)..<end]), display: true)
                        i = end + 2
                        continue
                    }
                } else if let next, !next.isWhitespace {    // $inline$
                    var j = i + 1
                    var found: Int?
                    while j < c.count {
                        if c[j] == "\\" { j += 2; continue }
                        if c[j] == "\n", j + 1 < c.count, c[j + 1] == "\n" { break }   // never across paragraphs
                        if c[j] == "$" {
                            let before = c[j - 1]
                            let after: Character? = j + 1 < c.count ? c[j + 1] : nil
                            if j > i + 1, !before.isWhitespace, !(after?.isNumber ?? false) { found = j }
                            break
                        }
                        j += 1
                    }
                    if let end = found {
                        emitMath(Array(c[(i + 1)..<end]), display: false)
                        i = end + 1
                        continue
                    }
                }
            }

            out.append(ch)
            i += 1
        }
        return out
    }

    /// Swaps the tokens in rendered HTML back for math elements (TeX is HTML-escaped).
    static func restore(_ html: String, _ formulas: [Formula]) -> String {
        guard !formulas.isEmpty else { return html }
        var html = html
        for (i, f) in formulas.enumerated().reversed() {   // reversed: FOLIOMATH1X must not hit FOLIOMATH10X
            let escaped = f.tex
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            let element = f.display
                ? "<span class=\"math display\">\(escaped)</span>"
                : "<span class=\"math\">\(escaped)</span>"
            html = html.replacingOccurrences(of: token(i), with: element)
        }
        return html
    }
}

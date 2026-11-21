#if DEBUG
import AppKit
import WebKit

/// Debug builds only: set FOLIO_SNAPSHOT_DIR to have each rendered page written
/// out as PNGs (whole window + full web view), for checking layout without a screen.
enum DebugSnapshot {
    static let dir = ProcessInfo.processInfo.environment["FOLIO_SNAPSHOT_DIR"].map(URL.init(fileURLWithPath:))

    @MainActor
    static func capture(_ webView: WKWebView) {
        guard let dir else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            MainActor.assumeIsolated {
                let stamp = Int(Date().timeIntervalSince1970 * 1000)
                webView.takeSnapshot(with: nil) { image, _ in
                    if let image { write(image, to: dir.appendingPathComponent("web-\(stamp).png")) }
                }
                if let view = webView.window?.contentView?.superview ?? webView.window?.contentView {
                    let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
                    view.cacheDisplay(in: view.bounds, to: rep)
                    try? rep.representation(using: .png, properties: [:])?
                        .write(to: dir.appendingPathComponent("window-\(stamp).png"))
                }
            }
        }
    }

    private static func write(_ image: NSImage, to url: URL) {
        guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return }
        try? rep.representation(using: .png, properties: [:])?.write(to: url)
    }
}
#endif

#if DEBUG
import SwiftUI

extension DebugSnapshot {
    /// FOLIO_TITLES_DIR: render the window title for several file kinds to one PNG.
    @MainActor
    static func renderTitles() {
        guard let path = ProcessInfo.processInfo.environment["FOLIO_TITLES_DIR"] else { return }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let names = ["/x/problemset05/CLAUDE.md", "\(home)/.claude/CLAUDE.md", "/x/folio/README.md",
                     "/x/skills/pdf/SKILL.md", "/x/repo/AGENTS.md", "/x/repo/CHANGELOG.md", "/x/notes/ideas.md"]
        for scheme in [ColorScheme.dark, .light] {
            let view = VStack(alignment: .leading, spacing: 14) {
                ForEach(names, id: \.self) { p in
                    let url = URL(fileURLWithPath: p)
                    DocumentTitle(name: url.lastPathComponent, subtitle: "291 words · 1 min read",
                                  special: SpecialFile.detect(url))
                }
            }
            .padding(20)
            .frame(width: 320, alignment: .leading)
            .background(scheme == .dark ? Color(white: 0.17) : Color(white: 0.96))
            .environment(\.colorScheme, scheme)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            if let image = renderer.nsImage, let tiff = image.tiffRepresentation,
               let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                try? png.write(to: URL(fileURLWithPath: path).appendingPathComponent("titles-\(scheme).png"))
            }
        }
    }
}
#endif

import AppKit
import SwiftUI
import WebKit

struct OutlineItem: Identifiable, Hashable {
    let id: String
    let level: Int
    let title: String
}

struct ScrollRequest: Equatable {
    let targetID: String
    let token = UUID()
}

struct FindRequest: Equatable {
    let query: String
    let step: Int          // 0 = search / refresh, 1 = next, -1 = previous
    let token = UUID()
}

struct MarkdownWebView: NSViewRepresentable {
    let html: String
    let baseURL: URL?
    let zoom: Double
    let scrollRequest: ScrollRequest?
    let onOutline: ([OutlineItem]) -> Void
    var findRequest: FindRequest? = nil
    var onFindResult: (_ count: Int, _ index: Int) -> Void = { _, _ in }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(LocalFileSchemeHandler(), forURLScheme: LocalFileSchemeHandler.scheme)
        config.userContentController.add(context.coordinator, name: "outline")
        config.userContentController.add(context.coordinator, name: "loadMermaid")
        config.userContentController.add(context.coordinator, name: "find")
        config.userContentController.add(context.coordinator, name: "loadMathJax")
        config.preferences.isElementFullscreenEnabled = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground") // no white flash in dark mode
        webView.allowsMagnification = true
        webView.isInspectable = true

        context.coordinator.webView = webView
        let dir = baseURL ?? URL(fileURLWithPath: NSHomeDirectory())
        webView.loadHTMLString(Renderer.shell, baseURL: LocalFileSchemeHandler.baseURL(for: dir))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let c = context.coordinator
        c.onOutline = onOutline
        c.onFindResult = onFindResult
        if webView.pageZoom != zoom { webView.pageZoom = zoom }
        c.show(html)
        if let scrollRequest, scrollRequest != c.lastScroll {
            c.lastScroll = scrollRequest
            c.call("scrollToId(id)", ["id": scrollRequest.targetID])
        }
        if let findRequest, findRequest != c.lastFind {
            c.lastFind = findRequest
            c.call("find(query, step, true)", ["query": findRequest.query, "step": findRequest.step])
        }
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var webView: WKWebView?
        var onOutline: ([OutlineItem]) -> Void = { _ in }
        var lastScroll: ScrollRequest?
        var lastFind: FindRequest?
        var onFindResult: (Int, Int) -> Void = { _, _ in }
        private var isLoaded = false
        private var shownHTML: String?
        private var pendingHTML: String?

        func show(_ html: String) {
            guard html != shownHTML else { return }
            if isLoaded {
                shownHTML = html
                call("render(html)", ["html": html])
            } else {
                pendingHTML = html
            }
        }

        func call(_ script: String, _ args: [String: Any]) {
            webView?.callAsyncJavaScript(script, arguments: args, in: nil, in: .page) { _ in }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            if let pendingHTML {
                self.pendingHTML = nil
                show(pendingHTML)
            }
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
            guard action.navigationType == .linkActivated, var url = action.request.url else {
                decisionHandler(.allow)
                return
            }
            decisionHandler(.cancel)
            if let file = LocalFileSchemeHandler.fileURL(from: url) { url = file }
            if url.isFileURL, ["md", "markdown", "mdown", "mkd", "mkdn", "mdx"].contains(url.pathExtension.lowercased()) {
                // Follow links to other Markdown files inside Folio.
                NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
            } else {
                NSWorkspace.shared.open(url)
            }
        }

        /// Injects the bundled Mermaid library (once per page) and renders the diagrams.
        private func loadMermaid() {
            guard let webView else { return }
            webView.evaluateJavaScript(Renderer.mermaidJS + "\n;0") { [weak webView] _, _ in
                webView?.evaluateJavaScript("renderMermaid(); 0")
            }
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "find", let body = message.body as? [String: Any] {
                onFindResult(body["count"] as? Int ?? 0, body["index"] as? Int ?? 0)
                #if DEBUG
                if let webView { DebugSnapshot.capture(webView) }
                #endif
                return
            }
            if message.name == "loadMathJax" {
                webView?.evaluateJavaScript(Renderer.mathJaxJS + "\n;0") { [weak webView] _, _ in
                    webView?.evaluateJavaScript("renderMath(); 0")
                }
                return
            }
            if message.name == "loadMermaid" {
                loadMermaid()
                return
            }
            guard message.name == "outline", let items = message.body as? [[String: Any]] else { return }
            #if DEBUG
            if let webView { DebugSnapshot.capture(webView) }
            #endif
            onOutline(items.compactMap { item in
                guard let id = item["id"] as? String,
                      let level = item["level"] as? Int,
                      let title = item["title"] as? String else { return nil }
                return OutlineItem(id: id, level: level, title: title)
            })
        }
    }
}

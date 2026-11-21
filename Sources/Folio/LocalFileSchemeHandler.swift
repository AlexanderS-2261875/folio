import Foundation
import UniformTypeIdentifiers
import WebKit

/// Serves local images/media referenced by a document (e.g. `![](img/shot.png)`).
/// The page is loaded with a `folio-file:///<doc dir>/` base URL so relative paths
/// resolve here. Only media types are served, so a document can't read arbitrary files.
final class LocalFileSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "folio-file"

    static func baseURL(for directory: URL) -> URL {
        var c = URLComponents()
        c.scheme = scheme
        c.host = ""
        c.path = directory.path.hasSuffix("/") ? directory.path : directory.path + "/"
        return c.url!
    }

    /// Maps a `folio-file:` URL back to the file on disk.
    static func fileURL(from url: URL) -> URL? {
        guard url.scheme == scheme else { return nil }
        return URL(fileURLWithPath: url.path(percentEncoded: false))
    }

    func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
        guard let url = task.request.url, let file = Self.fileURL(from: url) else {
            return task.didFailWithError(URLError(.badURL))
        }
        let type = UTType(filenameExtension: file.pathExtension)
        guard let type, type.conforms(to: .image) || type.conforms(to: .audiovisualContent),
              let data = try? Data(contentsOf: file) else {
            return task.didFailWithError(URLError(.fileDoesNotExist))
        }
        let response = URLResponse(url: url, mimeType: type.preferredMIMEType ?? "application/octet-stream",
                                   expectedContentLength: data.count, textEncodingName: nil)
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {}
}

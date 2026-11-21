import SwiftUI

@main
struct FolioApp: App {
    @AppStorage("zoom") private var zoom = 1.0

    init() {
        #if DEBUG
        DebugSnapshot.renderTitles()
        #endif
    }

    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            ReaderView(documentText: file.document.text, fileURL: file.fileURL)
        }
        .defaultSize(width: 980, height: 1000)
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Actual Size") { zoom = 1.0 }
                    .keyboardShortcut("0")
                Button("Zoom In") { zoom = min(zoom + 0.1, 3.0) }
                    .keyboardShortcut("+")
                Button("Zoom Out") { zoom = max(zoom - 0.1, 0.5) }
                    .keyboardShortcut("-")
                Divider()
            }
        }
    }
}

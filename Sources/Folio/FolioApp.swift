import SwiftUI

@main
struct FolioApp: App {
    @AppStorage("zoom") private var zoom = 1.0
    @FocusedValue(\.reader) private var reader

    init() {
        #if DEBUG
        DebugSnapshot.renderTitles()
        if let look = ProcessInfo.processInfo.environment["FOLIO_APPEARANCE"] {
            NSApplication.shared.appearance = NSAppearance(named: look == "dark" ? .darkAqua : .aqua)
        }
        #endif
    }

    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            ReaderView(documentText: file.document.text, fileURL: file.fileURL)
        }
        .defaultSize(width: 980, height: 1000)
        .commands {
            CommandGroup(replacing: .textEditing) {
                Button("Find…") { reader?.showFind() }
                    .keyboardShortcut("f")
                Button("Find Next") { reader?.step(1) }
                    .keyboardShortcut("g")
                Button("Find Previous") { reader?.step(-1) }
                    .keyboardShortcut("g", modifiers: [.command, .shift])
            }
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

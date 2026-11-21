import SwiftUI

struct ReaderView: View {
    let documentText: String
    let fileURL: URL?

    @State private var text: String
    @State private var html: String
    @State private var outline: [OutlineItem] = []
    @State private var scrollRequest: ScrollRequest?
    @State private var watcher = FileWatcher()
    @State private var columns: NavigationSplitViewVisibility
    @AppStorage("zoom") private var zoom = 1.0
    @AppStorage("showOutline") private var showOutline = true

    init(documentText: String, fileURL: URL?) {
        self.documentText = documentText
        self.fileURL = fileURL
        _text = State(initialValue: documentText)
        _html = State(initialValue: Renderer.body(from: documentText))
        let show = UserDefaults.standard.object(forKey: "showOutline") as? Bool ?? true
        _columns = State(initialValue: show ? .all : .detailOnly)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columns) {
            sidebar
                .navigationSplitViewColumnWidth(min: 180, ideal: 230, max: 360)
                .toolbar(removing: .sidebarToggle) // must sit on the sidebar column to take effect
        } detail: {
            MarkdownWebView(
                html: html,
                baseURL: fileURL?.deletingLastPathComponent(),
                zoom: zoom,
                scrollRequest: scrollRequest,
                onOutline: { outline = $0 }
            )
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            watcher.watch(fileURL) { update($0) }
        }
        .onChange(of: documentText) { _, newValue in update(newValue) }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation { columns = columns == .detailOnly ? .all : .detailOnly }
                    showOutline = columns != .detailOnly
                } label: {
                    Label("Outline", systemImage: "sidebar.left")
                }
                .help("Show or hide the outline")
            }
            ToolbarItem(placement: .navigation) {
                DocumentTitle(name: fileURL?.lastPathComponent ?? "Untitled",
                              subtitle: Renderer.stats(for: text),
                              special: SpecialFile.detect(fileURL))
            }
            .sharedBackgroundVisibility(.hidden) // plain title, no glass capsule
        }
        .toolbar(removing: .title) // our DocumentTitle replaces the system title
    }

    @ViewBuilder
    private var sidebar: some View {
        if outline.isEmpty {
            ContentUnavailableView("No Headings", systemImage: "list.bullet.indent")
        } else {
            List(outline) { item in
                Button {
                    scrollRequest = ScrollRequest(targetID: item.id)
                } label: {
                    Text(item.title)
                        .font(item.level == 1 ? .body.weight(.semibold) : .body)
                        .foregroundStyle(item.level > 2 ? .secondary : .primary)
                        .lineLimit(2)
                        .padding(.leading, CGFloat(max(0, item.level - 1)) * 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.sidebar)
        }
    }

    private func update(_ newText: String) {
        guard newText != text else { return }
        text = newText
        html = Renderer.body(from: newText)
    }
}

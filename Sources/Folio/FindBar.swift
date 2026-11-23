import SwiftUI

/// Actions the menu bar can send to the reader in the key window.
struct ReaderActions {
    let showFind: () -> Void
    let step: (Int) -> Void
}

extension FocusedValues {
    @Entry var reader: ReaderActions?
}

/// Floating find field (⌘F): highlights every match, Enter/⇧Enter steps, Esc closes.
struct FindBar: View {
    @Binding var query: String
    let count: Int
    let index: Int
    var focused: FocusState<Bool>.Binding
    let onStep: (Int) -> Void
    let onClose: () -> Void

    private var status: String {
        if query.isEmpty { return "" }
        return count == 0 ? "No results" : "\(index) of \(count)"
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Find", text: $query)
                .textFieldStyle(.plain)
                .frame(width: 170)
                .focused(focused)
                .onKeyPress(.return, phases: .down) { press in
                    onStep(press.modifiers.contains(.shift) ? -1 : 1)
                    return .handled
                }
                .onKeyPress(.escape) {
                    onClose()
                    return .handled
                }
            Text(status)
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(count == 0 && !query.isEmpty ? .red : .secondary)
                .fixedSize()
            Group {
                Button { onStep(-1) } label: { Image(systemName: "chevron.up") }
                    .help("Previous match (⇧⌘G)")
                Button { onStep(1) } label: { Image(systemName: "chevron.down") }
                    .help("Next match (⌘G)")
            }
            .disabled(count == 0)
            Button(action: onClose) { Image(systemName: "xmark.circle.fill") }
                .foregroundStyle(.secondary)
                .help("Close (Esc)")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .glassEffect(.regular, in: .capsule)
        .padding(12)
    }
}

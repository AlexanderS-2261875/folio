import Foundation

/// Watches a file on disk and reports its new contents. Survives the
/// "write to temp file, then rename over the original" saves most editors do.
@MainActor
final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var url: URL?
    private var onChange: ((String) -> Void)?
    private var reloadScheduled = false

    func watch(_ url: URL?, onChange: @escaping (String) -> Void) {
        guard let url, url != self.url else { return }
        self.url = url
        self.onChange = onChange
        arm(attempt: 0)
    }

    private func arm(attempt: Int) {
        source?.cancel()
        source = nil
        guard let url else { return }

        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            // The file may be mid-replace; try again shortly.
            if attempt < 20 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    MainActor.assumeIsolated { self?.arm(attempt: attempt + 1) }
                }
            }
            return
        }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .extend, .delete, .rename], queue: .main)
        src.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                guard let self, let source = self.source else { return }
                let event = source.data
                if event.contains(.delete) || event.contains(.rename) {
                    // Original inode is gone; re-attach to whatever now lives at the path.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                        MainActor.assumeIsolated {
                            self?.arm(attempt: 0)
                            self?.scheduleReload()
                        }
                    }
                } else {
                    self.scheduleReload()
                }
            }
        }
        src.setCancelHandler { close(fd) }
        src.resume()
        source = src
    }

    private func scheduleReload() {
        guard !reloadScheduled else { return }
        reloadScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.reloadScheduled = false
                guard let url = self.url, let data = try? Data(contentsOf: url) else { return }
                self.onChange?(String(decoding: data, as: UTF8.self))
            }
        }
    }

    func reloadNow() { scheduleReload() }

    isolated deinit { source?.cancel() }
}

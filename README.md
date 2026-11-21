# Folio

A clean, native Markdown reader for macOS. Open a `.md` file and read it, nicely typeset, with nothing in the way.

## Features

- **GitHub-flavoured Markdown** via Apple's [swift-markdown](https://github.com/swiftlang/swift-markdown): tables, task lists, strikethrough
- **Syntax highlighting** for 36 languages, fully offline
- **Outline sidebar** built from your headings — click to jump
- **Live reload** when the file changes on disk (also with editors that save by replacing the file)
- **Knows special files**: `CLAUDE.md`, `SKILL.md`, `AGENTS.md`, `README`, `CHANGELOG`, `CONTRIBUTING`, `LICENSE` and `SECURITY` get a coloured title and icon; click the name for what the file is and a link to its docs
- Light and dark mode, relative images, links to other `.md` files open in Folio
- ⌘+ / ⌘− / ⌘0 zoom · word count and reading time in the title bar
- Raw HTML in a document can't run scripts or make network requests (Content-Security-Policy)

## Install

Requires macOS 26 or later.

1. Download `Folio.zip` from the [latest release](../../releases/latest) and unzip it.
2. Move `Folio.app` to Applications.
3. Folio isn't notarized, so the first time macOS will refuse to open it. Right-click it → **Open**, or run:
   ```sh
   xattr -dr com.apple.quarantine /Applications/Folio.app
   ```

Open files with right-click → **Open With → Folio**, by dragging them onto the app, or `open -a Folio file.md`.
To make Folio the default for Markdown: Get Info on any `.md` file → **Open with** → Folio → **Change All**.

## Build from source

Needs Xcode 26 or later.

```sh
./build.sh            # → build/Folio.app
./build.sh --install  # also copies it to ~/Applications
```

The `sample/` folder has documents that exercise every feature.

Debug builds can snapshot their own window for checking layout without a screen: run with `FOLIO_SNAPSHOT_DIR=/some/dir`.

## Credits

- [swift-markdown](https://github.com/swiftlang/swift-markdown) (Apache-2.0) for parsing
- [highlight.js](https://highlightjs.org) 11.12.0 (BSD-3-Clause), bundled in `Resources/` for syntax highlighting

## License

Folio is released under the [MIT License](LICENSE). Bundled third-party code keeps its own license (see Credits).

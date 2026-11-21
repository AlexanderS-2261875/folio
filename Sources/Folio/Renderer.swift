import Foundation
import Markdown

enum Renderer {
    /// Markdown → HTML body fragment (GitHub-flavoured: tables, task lists, strikethrough).
    static func body(from markdown: String) -> String {
        let document = Document(parsing: markdown, options: [.parseBlockDirectives])
        return HTMLFormatter.format(document, options: [.parseAsides])
    }

    static func stats(for markdown: String) -> String {
        let words = markdown.split { $0.isWhitespace || $0.isNewline }.count
        let minutes = max(1, Int((Double(words) / 230).rounded()))
        let formatted = words.formatted(.number)
        return "\(formatted) words · \(minutes) min read"
    }

    /// The page shell is loaded once; content is swapped in via `render(html)` so
    /// live reloads keep the scroll position and never flash.
    static let shell = """
    <!doctype html>
    <html>
    <head>
    <meta charset="utf-8">
    <meta name="color-scheme" content="light dark">
    <meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'nonce-folio'; style-src 'unsafe-inline'; img-src folio-file: https: http: data:; media-src folio-file: https: http:; font-src data:">
    <style>\(css)</style>
    </head>
    <body>
    <article id="content"></article>
    <script nonce="folio">\(highlightJS)</script>
    <script nonce="folio">\(js)</script>
    </body>
    </html>
    """

    /// highlight.js (BSD-3-Clause), bundled in Contents/Resources — no network needed.
    static let highlightJS: String = Bundle.main.url(forResource: "highlight.min", withExtension: "js")
        .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""

    static let css = """
    :root {
      --bg: #ffffff;
      --fg: #1d1d1f;
      --muted: #6e6e73;
      --rule: #e5e5ea;
      --link: #0a66d8;
      --code-bg: #f5f5f7;
      --code-fg: #1d1d1f;
      --quote: #d2d2d7;
      --mark: #fff3b0;
      --table-alt: #fafafa;
      --hl-keyword: #cf222e;
      --hl-string: #0a3069;
      --hl-comment: #6e7781;
      --hl-number: #0550ae;
      --hl-title: #8250df;
      --hl-type: #953800;
      --hl-tag: #116329;
      --hl-add-bg: #dafbe1;
      --hl-del-bg: #ffebe9;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #1e1e1f;
        --fg: #e8e8ed;
        --muted: #98989d;
        --rule: #38383a;
        --link: #5aa9ff;
        --code-bg: #2a2a2c;
        --code-fg: #e8e8ed;
        --quote: #48484a;
        --mark: #5c4b00;
        --table-alt: #232325;
        --hl-keyword: #ff7b72;
        --hl-string: #a5d6ff;
        --hl-comment: #8b949e;
        --hl-number: #79c0ff;
        --hl-title: #d2a8ff;
        --hl-type: #ffa657;
        --hl-tag: #7ee787;
        --hl-add-bg: #12361b;
        --hl-del-bg: #4a1618;
      }
    }
    * { box-sizing: border-box; }
    html { background: var(--bg); }
    body {
      margin: 0;
      background: var(--bg);
      color: var(--fg);
      font: 16px/1.68 -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif;
      -webkit-font-smoothing: antialiased;
      text-rendering: optimizeLegibility;
      font-kerning: normal;
    }
    article {
      max-width: 46rem;
      margin: 0 auto;
      padding: 3.5rem 2.5rem 6rem;
      overflow-wrap: break-word;
    }
    article > :first-child { margin-top: 0; }
    h1, h2, h3, h4, h5, h6 {
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
      line-height: 1.25;
      font-weight: 650;
      letter-spacing: -0.012em;
      margin: 2.2em 0 0.7em;
      scroll-margin-top: 1.5rem;
    }
    h1 { font-size: 2.1em; font-weight: 700; letter-spacing: -0.022em; margin-top: 0.4em; }
    h2 { font-size: 1.55em; padding-bottom: 0.3em; border-bottom: 1px solid var(--rule); }
    h3 { font-size: 1.25em; }
    h4 { font-size: 1.05em; }
    h5, h6 { font-size: 0.95em; color: var(--muted); }
    p, ul, ol, blockquote, pre, table, figure { margin: 0 0 1.1em; }
    a { color: var(--link); text-decoration: none; }
    a:hover { text-decoration: underline; text-underline-offset: 0.15em; }
    strong { font-weight: 650; }
    ul, ol { padding-left: 1.6em; }
    li { margin: 0.3em 0; }
    li > p { margin: 0; }
    li > p + p { margin-top: 0.6em; }
    li > input[type=checkbox] + p { display: inline; }
    li > ul, li > ol { margin: 0.25em 0 0; }
    li:has(> input[type=checkbox]) { list-style: none; margin-left: -1.4em; }
    input[type=checkbox] { margin: 0 0.45em 0 0; vertical-align: -0.1em; accent-color: var(--link); }
    blockquote {
      margin-left: 0;
      padding: 0.1em 1.1em;
      border-left: 3px solid var(--quote);
      color: var(--muted);
    }
    blockquote > :last-child { margin-bottom: 0; }
    aside {
      margin: 0 0 1.1em;
      padding: 0.8em 1.1em;
      border-radius: 8px;
      background: var(--code-bg);
      border-left: 3px solid var(--link);
    }
    aside > :last-child { margin-bottom: 0; }
    code, pre, kbd {
      font-family: ui-monospace, "SF Mono", Menlo, monospace;
      font-size: 0.87em;
    }
    :not(pre) > code {
      padding: 0.12em 0.38em;
      border-radius: 5px;
      background: var(--code-bg);
      color: var(--code-fg);
    }
    pre {
      padding: 1em 1.2em;
      border-radius: 10px;
      background: var(--code-bg);
      color: var(--code-fg);
      overflow-x: auto;
      line-height: 1.5;
    }
    pre code { font-size: 0.85em; }
    pre { position: relative; }
    pre[data-lang]::before {
      content: attr(data-lang);
      position: absolute;
      top: 0.55em;
      right: 0.9em;
      font: 600 0.68em/1 -apple-system, sans-serif;
      letter-spacing: 0.06em;
      text-transform: uppercase;
      color: var(--muted);
      opacity: 0.8;
    }
    .hljs-keyword, .hljs-selector-tag, .hljs-meta .hljs-keyword, .hljs-doctag { color: var(--hl-keyword); }
    .hljs-string, .hljs-regexp, .hljs-meta .hljs-string, .hljs-char.escape_ { color: var(--hl-string); }
    .hljs-comment, .hljs-quote, .hljs-meta { color: var(--hl-comment); font-style: italic; }
    .hljs-meta { font-style: normal; }
    .hljs-number, .hljs-literal, .hljs-attr, .hljs-attribute, .hljs-property, .hljs-symbol,
    .hljs-variable.language_, .hljs-selector-attr, .hljs-selector-class, .hljs-selector-id,
    .hljs-operator, .hljs-link { color: var(--hl-number); }
    .hljs-title, .hljs-title.function_, .hljs-title.class_.inherited__, .hljs-section { color: var(--hl-title); }
    .hljs-type, .hljs-built_in, .hljs-title.class_, .hljs-variable, .hljs-template-variable,
    .hljs-params, .hljs-selector-pseudo { color: var(--hl-type); }
    .hljs-params { color: inherit; }
    .hljs-name, .hljs-tag, .hljs-bullet { color: var(--hl-tag); }
    .hljs-section, .hljs-strong { font-weight: 600; }
    .hljs-emphasis { font-style: italic; }
    .hljs-addition { color: var(--hl-tag); background: var(--hl-add-bg); }
    .hljs-deletion { color: var(--hl-keyword); background: var(--hl-del-bg); }
    kbd {
      padding: 0.1em 0.4em;
      border: 1px solid var(--rule);
      border-bottom-width: 2px;
      border-radius: 4px;
    }
    hr { border: 0; border-top: 1px solid var(--rule); margin: 2.5em 0; }
    img, video { max-width: 100%; height: auto; border-radius: 6px; }
    table {
      border-collapse: collapse;
      display: block;
      width: max-content;
      max-width: 100%;
      overflow-x: auto;
      font-size: 0.94em;
    }
    th, td { padding: 0.5em 0.9em; border: 1px solid var(--rule); }
    th { font-weight: 600; background: var(--code-bg); }
    tbody tr:nth-child(even) { background: var(--table-alt); }
    mark { background: var(--mark); color: inherit; padding: 0 0.15em; border-radius: 3px; }
    ::selection { background: color-mix(in srgb, var(--link) 28%, transparent); }
    """

    static let js = """
    const content = document.getElementById('content');

    function slugify(text, used) {
      let base = text.toLowerCase().trim()
        .replace(/[^\\p{L}\\p{N}\\s-]/gu, '')
        .replace(/\\s+/g, '-') || 'section';
      let slug = base, n = 1;
      while (used.has(slug)) slug = `${base}-${n++}`;
      used.add(slug);
      return slug;
    }

    if (window.hljs) hljs.configure({ ignoreUnescapedHTML: true });

    function highlight() {
      content.querySelectorAll('pre > code[class*="language-"]').forEach(el => {
        const match = el.className.match(/language-([\\w+#.-]+)/);
        if (!match) return;
        const lang = match[1].toLowerCase();
        el.parentElement.dataset.lang = lang;
        if (window.hljs && hljs.getLanguage(lang)) hljs.highlightElement(el);
      });
    }

    function decorate() {
      highlight();
      const used = new Set();
      const outline = [];
      content.querySelectorAll('h1, h2, h3, h4, h5, h6').forEach(h => {
        h.id = slugify(h.textContent, used);
        outline.push({ id: h.id, level: Number(h.tagName[1]), title: h.textContent.trim() });
      });
      window.webkit.messageHandlers.outline.postMessage(outline);
    }

    function render(html) {
      const y = window.scrollY;
      content.innerHTML = html;
      decorate();
      window.scrollTo(0, y);
    }

    function scrollToId(id) {
      const el = document.getElementById(id);
      if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }

    // In-page anchors scroll locally instead of navigating.
    document.addEventListener('click', e => {
      const a = e.target.closest('a[href^="#"]');
      if (!a) return;
      e.preventDefault();
      scrollToId(decodeURIComponent(a.getAttribute('href').slice(1)));
    });
    """
}

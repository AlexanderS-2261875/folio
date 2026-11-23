import Foundation
import Markdown

enum Renderer {
    /// Markdown → HTML body fragment (GitHub-flavoured: tables, task lists, strikethrough).
    static func body(from markdown: String) -> String {
        let (protected, formulas) = MathExtractor.extract(markdown)
        let document = Document(parsing: protected, options: [.parseBlockDirectives])
        return MathExtractor.restore(HTMLFormatter.format(document, options: [.parseAsides]), formulas)
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

    /// Mermaid (MIT), bundled in Contents/Resources. 5.5 MB, so it is only injected
    /// into a page once that page actually contains a ```mermaid block.
    static let mermaidJS: String = Bundle.main.url(forResource: "mermaid.min", withExtension: "js")
        .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""

    /// MathJax 3.2.2 (Apache-2.0), self-contained SVG build with every TeX extension,
    /// injected only into pages that contain math.
    static let mathJaxJS: String = Bundle.main.url(forResource: "mathjax.min", withExtension: "js")
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
    .mermaid-diagram {
      margin: 0 0 1.1em;
      display: flex;
      justify-content: center;
      overflow-x: auto;
      min-height: 2em;
    }
    .mermaid-diagram svg { max-width: 100%; height: auto; }
    .mermaid-diagram.error {
      display: block;
      padding: 0.8em 1.1em;
      border-radius: 8px;
      background: var(--code-bg);
      border-left: 3px solid var(--hl-keyword);
    }
    .mermaid-error-title { color: var(--hl-keyword); font-size: 0.88em; font-weight: 600; margin-bottom: 0.5em; }
    .mermaid-diagram.error pre { margin: 0; padding: 0; background: none; }
    .math { font-size: 1.05em; }
    .math:not(.rendered) { font-family: ui-monospace, "SF Mono", Menlo, monospace; font-size: 0.87em; color: var(--muted); }
    .math.display { display: block; margin: 1.1em 0; text-align: center; overflow-x: auto; overflow-y: hidden; }
    .math.error { color: var(--hl-keyword); }
    .math [data-mml-node="merror"] > rect { fill: color-mix(in srgb, var(--hl-keyword) 14%, transparent) !important; }
    .math [data-mml-node="merror"] g { fill: var(--hl-keyword) !important; stroke: none; }
    ::highlight(folio-find) { background-color: rgba(255, 204, 0, 0.35); }
    ::highlight(folio-find-current) { background-color: #ffcc00; color: #000; }
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
        if (lang === 'mermaid') return;
        el.parentElement.dataset.lang = lang;
        if (window.hljs && hljs.getLanguage(lang)) hljs.highlightElement(el);
      });
    }

    // ---- Mermaid -------------------------------------------------------------
    const isDark = () => window.matchMedia('(prefers-color-scheme: dark)').matches;
    const svgCache = new Map();   // "dark|source" -> svg, so live reloads don't flicker
    let mermaidRequested = false;

    // Diagram colours drawn from Folio's own palette.
    const mermaidLight = {
      darkMode: false, background: 'transparent', fontSize: '15px',
      primaryColor: '#eaf2ff', primaryTextColor: '#1d1d1f', primaryBorderColor: '#a9c6f2',
      secondaryColor: '#f3ecfe', secondaryBorderColor: '#cdb6f3',
      tertiaryColor: '#f5f5f7', tertiaryBorderColor: '#d2d2d7',
      lineColor: '#86868b', textColor: '#1d1d1f',
      mainBkg: '#eaf2ff', nodeBorder: '#a9c6f2', clusterBkg: '#f5f5f7', clusterBorder: '#d2d2d7',
      edgeLabelBackground: '#ffffff', pieOpacity: '0.92',
      noteBkgColor: '#fff8d6', noteBorderColor: '#e3c55b', noteTextColor: '#1d1d1f',
      actorBkg: '#eaf2ff', actorBorder: '#a9c6f2', actorTextColor: '#1d1d1f',
      signalColor: '#6e6e73', signalTextColor: '#1d1d1f', labelBoxBkgColor: '#f5f5f7',
      pie1: '#0a66d8', pie2: '#8250df', pie3: '#d97757', pie4: '#1a7f37', pie5: '#bf8700',
      pie6: '#cf222e', pie7: '#0598bc', pie8: '#6e6e73',
      pieStrokeColor: '#ffffff', pieStrokeWidth: '2px', pieOuterStrokeWidth: '0px',
      pieSectionTextColor: '#ffffff', pieTitleTextColor: '#1d1d1f', pieLegendTextColor: '#1d1d1f',
    };
    const mermaidDark = {
      darkMode: true, background: 'transparent', fontSize: '15px',
      primaryColor: '#1f2b40', primaryTextColor: '#e8e8ed', primaryBorderColor: '#3f5f93',
      secondaryColor: '#2c2440', secondaryBorderColor: '#5b478c',
      tertiaryColor: '#2a2a2c', tertiaryBorderColor: '#48484a',
      lineColor: '#98989d', textColor: '#e8e8ed',
      mainBkg: '#1f2b40', nodeBorder: '#3f5f93', clusterBkg: '#2a2a2c', clusterBorder: '#48484a',
      edgeLabelBackground: '#1e1e1f', pieOpacity: '0.92',
      noteBkgColor: '#3a3318', noteBorderColor: '#8a7424', noteTextColor: '#e8e8ed',
      actorBkg: '#1f2b40', actorBorder: '#3f5f93', actorTextColor: '#e8e8ed',
      signalColor: '#98989d', signalTextColor: '#e8e8ed', labelBoxBkgColor: '#2a2a2c',
      pie1: '#5aa9ff', pie2: '#b48cf2', pie3: '#e8956f', pie4: '#56d364', pie5: '#e3b341',
      pie6: '#ff7b72', pie7: '#39c5cf', pie8: '#98989d',
      pieStrokeColor: '#1e1e1f', pieStrokeWidth: '2px', pieOuterStrokeWidth: '0px',
      pieSectionTextColor: '#1e1e1f', pieTitleTextColor: '#e8e8ed', pieLegendTextColor: '#e8e8ed',
    };
    let mermaidSeq = 0;
    // Keep diagrams at their natural size (CSS still shrinks them to fit) instead of
    // stretching small diagrams to the full column width.
    const naturalSize = Object.fromEntries(
      ['pie', 'gantt', 'class', 'state', 'er', 'journey', 'gitGraph', 'mindmap', 'timeline',
       'quadrantChart', 'xyChart', 'requirement', 'sankey', 'block', 'architecture', 'packet', 'radar', 'kanban']
        .map(k => [k, { useMaxWidth: false }]));

    function prepareMermaid() {
      content.querySelectorAll('pre > code.language-mermaid').forEach(code => {
        const div = document.createElement('div');
        div.className = 'mermaid-diagram';
        div.dataset.source = code.textContent;
        const cached = svgCache.get(`${isDark()}|${div.dataset.source}`);
        if (cached) div.innerHTML = cached;
        code.parentElement.replaceWith(div);
      });
    }

    function showMermaidError(node, error) {
      node.classList.add('error');
      const title = document.createElement('div');
      title.className = 'mermaid-error-title';
      title.textContent = 'Mermaid: ' + String(error && error.message || error).split('\\n')[0];
      const pre = document.createElement('pre');
      pre.textContent = node.dataset.source;
      node.replaceChildren(title, pre);
    }

    async function renderMermaid() {
      const nodes = [...content.querySelectorAll('.mermaid-diagram')];
      if (!nodes.length) return;
      if (!window.mermaid) {
        if (!mermaidRequested) {
          mermaidRequested = true;
          window.webkit.messageHandlers.loadMermaid.postMessage(null);
        }
        return;
      }
      const dark = isDark();
      mermaid.initialize({
        startOnLoad: false,
        securityLevel: 'strict',
        theme: 'base',
        fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif',
        suppressErrorRendering: true,
        themeVariables: dark ? mermaidDark : mermaidLight,
        ...naturalSize,
        sequence: { useMaxWidth: false, mirrorActors: false, width: 130, height: 44, actorMargin: 60, boxMargin: 8 },
        flowchart: { useMaxWidth: false, curve: 'basis', padding: 14 },
      });
      for (const node of nodes) {
        const key = `${dark}|${node.dataset.source}`;
        if (svgCache.has(key)) { node.innerHTML = svgCache.get(key); node.classList.remove('error'); continue; }
        const id = `folio-mermaid-${++mermaidSeq}`;
        try {
          const { svg } = await mermaid.render(id, node.dataset.source);
          svgCache.set(key, svg);
          node.classList.remove('error');
          node.innerHTML = svg;
        } catch (error) {
          document.getElementById('d' + id)?.remove();
          showMermaidError(node, error);
        }
      }
    }

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', renderMermaid);

    // ---- Math (MathJax) ----------------------------------------------------
    let mathRequested = false;

    function prepareMath() {
      // ```math blocks (GitHub syntax) become display math.
      content.querySelectorAll('pre > code.language-math').forEach(code => {
        const span = document.createElement('span');
        span.className = 'math display';
        span.textContent = code.textContent;
        code.parentElement.replaceWith(span);
      });
    }

    async function renderMath() {
      const nodes = [...content.querySelectorAll('.math:not(.rendered)')];
      if (!nodes.length) return;
      if (!(window.MathJax && MathJax.startup)) {
        if (!mathRequested) {
          mathRequested = true;
          window.MathJax = {
            startup: { typeset: false },
            svg: { fontCache: 'local' },
            tex: { packages: { '[+]': ['ams', 'boldsymbol', 'mathtools', 'physics'] } },
          };
          window.webkit.messageHandlers.loadMathJax.postMessage(null);
        }
        return;
      }
      await MathJax.startup.promise;
      if (!document.getElementById('MJX-SVG-styles')) {
        // tex2svg doesn't add MathJax's CSS, which hides the screen-reader MathML copy.
        document.head.appendChild(MathJax.svgStylesheet());
      }
      for (const node of nodes) {
        const tex = node.dataset.tex ?? node.textContent;
        node.dataset.tex = tex;
        const display = node.classList.contains('display');
        try {
          node.replaceChildren(MathJax.tex2svg(tex, { display }));
          node.classList.add('rendered');
          node.title = tex;
        } catch (error) {
          node.classList.add('error');
        }
      }
    }

    // ---- Find (⌘F) -------------------------------------------------------
    // Uses the CSS Custom Highlight API, so the DOM is never modified and
    // matches that span highlighted code tokens still work.
    let findQuery = '';
    let findRanges = [];
    let findIndex = -1;

    function findTextNodes() {
      const walker = document.createTreeWalker(content, NodeFilter.SHOW_TEXT, {
        acceptNode: n => n.parentElement.closest('svg, style, script')
          ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT,
      });
      const nodes = [];
      while (walker.nextNode()) nodes.push(walker.currentNode);
      return nodes;
    }

    // step 0 = (re)search, keeping the current match where possible; ±1 = next/previous.
    function find(query, step, scroll) {
      if (step === 0) {
        const keep = query === findQuery ? findIndex : 0;
        findQuery = query;
        findRanges = [];
        if (query) {
          const nodes = findTextNodes();
          const starts = [];
          let text = '';
          for (const n of nodes) { starts.push(text.length); text += n.data; }
          const locate = pos => {
            let lo = 0, hi = nodes.length - 1;
            while (lo < hi) { const mid = (lo + hi + 1) >> 1; if (starts[mid] <= pos) lo = mid; else hi = mid - 1; }
            return [nodes[lo], pos - starts[lo]];
          };
          const hay = text.toLowerCase();
          const needle = query.toLowerCase();
          for (let i = hay.indexOf(needle); i !== -1; i = hay.indexOf(needle, i + needle.length)) {
            const range = document.createRange();
            range.setStart(...locate(i));
            const [endNode, endOffset] = locate(i + needle.length - 1);
            range.setEnd(endNode, endOffset + 1);
            findRanges.push(range);
          }
        }
        findIndex = findRanges.length ? Math.min(Math.max(keep, 0), findRanges.length - 1) : -1;
      } else if (findRanges.length) {
        findIndex = (findIndex + step + findRanges.length) % findRanges.length;
      }

      CSS.highlights.set('folio-find', new Highlight(...findRanges));
      const current = findIndex >= 0 ? new Highlight(findRanges[findIndex]) : new Highlight();
      current.priority = 1;
      CSS.highlights.set('folio-find-current', current);

      if (scroll && findIndex >= 0) {
        const rect = findRanges[findIndex].getBoundingClientRect();
        if (rect.top < 60 || rect.bottom > window.innerHeight - 40) {
          window.scrollBy({ top: rect.top - window.innerHeight / 3, behavior: 'smooth' });
        }
      }
      window.webkit.messageHandlers.find.postMessage({ count: findRanges.length, index: findIndex + 1 });
    }

    function decorate() {
      prepareMath();
      prepareMermaid();
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
      if (findQuery) find(findQuery, 0, false);  // keep highlights across live reloads
      renderMath();
      renderMermaid();
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

import { marked } from "marked";

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function isSafeHref(href: string): boolean {
  return /^(https?:|mailto:|\/|#)/i.test(href.trim());
}

/**
 * Page bodies are written by anyone on the team and rendered with raw(), so
 * raw HTML in the source comes out as text and a link or image can only point
 * somewhere ordinary.
 */
marked.use({
  gfm: true,
  renderer: {
    html(token) {
      return escapeHtml(token.text);
    },

    link(token) {
      let text = this.parser.parseInline(token.tokens);

      if (!isSafeHref(token.href)) {
        return text;
      }

      let title = token.title ? ` title="${escapeHtml(token.title)}"` : "";
      let external = /^https?:/i.test(token.href) ? ` target="_blank" rel="noopener"` : "";

      return `<a href="${escapeHtml(token.href)}"${title}${external}>${text}</a>`;
    },

    image(token) {
      if (!isSafeHref(token.href)) {
        return escapeHtml(token.text);
      }

      return `<img src="${escapeHtml(token.href)}" alt="${escapeHtml(token.text)}" loading="lazy">`;
    },
  },
});

export function renderMarkdown(source: string): string {
  return marked.parse(source, { async: false }) as string;
}

export { escapeHtml };

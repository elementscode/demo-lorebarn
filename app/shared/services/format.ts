export function timeAgo(date: Date, now: Date = new Date()): string {
  let seconds = Math.max(0, Math.round((+now - +date) / 1000));

  if (seconds < 45) {
    return "just now";
  }

  let minutes = Math.round(seconds / 60);

  if (minutes < 60) {
    return `${minutes}m ago`;
  }

  let hours = Math.round(minutes / 60);

  if (hours < 24) {
    return `${hours}h ago`;
  }

  let days = Math.round(hours / 24);

  if (days < 7) {
    return days === 1 ? "yesterday" : `${days}d ago`;
  }

  return date.toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

export function formatDateTime(date: Date): string {
  return date.toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
}

export function initials(name: string): string {
  let parts = name.trim().split(/\s+/);

  return ((parts[0]?.[0] ?? "") + (parts.length > 1 ? parts[parts.length - 1][0] : "")).toUpperCase();
}

/**
 * A stable hue per person, so the same teammate has the same avatar color in
 * the presence bar, the history and the member list.
 */
export function avatarHue(id: string): number {
  let hash = 0;

  for (let i = 0; i < id.length; i++) {
    hash = (hash * 31 + id.charCodeAt(i)) | 0;
  }

  return Math.abs(hash) % 360;
}

// The page's prose, for a one or two line preview: code blocks, headings,
// tables and list markers are left out, and links keep only their text.
export function excerpt(markdown: string, length: number = 140): string {
  let prose: string[] = [];
  let items: string[] = [];
  let inCode = false;

  for (let line of markdown.split("\n")) {
    let trimmed = line.trim();
    if (trimmed.startsWith("```")) {
      inCode = !inCode;
      continue;
    }

    if (inCode || !trimmed || /^(#|\||>|---|\*\*\*)/.test(trimmed)) {
      continue;
    }

    let item = trimmed.match(/^(?:[-*+]|\d+\.)\s+(?:\[[ xX]\]\s+)?(.*)$/);
    if (item) {
      items.push(item[1]);
      continue;
    }

    prose.push(trimmed);
  }

  let text = (prose.length ? prose : items)
    .join(" ")
    .replace(/!?\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/[*_`]/g, "")
    .replace(/\s+/g, " ")
    .trim();

  return text.length > length ? text.slice(0, length).replace(/\s+\S*$/, "") + "…" : text;
}

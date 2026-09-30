import { diffLines, diffWordsWithSpace } from "diff";

export interface DiffPart {
  text: string;
  changed: boolean;
}

export interface DiffRow {
  id: string;
  kind: "same" | "add" | "del" | "gap";
  oldNo: number | null;
  newNo: number | null;
  parts: DiffPart[];
}

export interface DiffStats {
  added: number;
  removed: number;
}

const CONTEXT = 3;

function splitLines(value: string): string[] {
  let lines = value.split("\n");

  if (lines.at(-1) === "") {
    lines.pop();
  }

  return lines;
}

function wordParts(before: string, after: string): { del: DiffPart[]; add: DiffPart[] } {
  let del: DiffPart[] = [];
  let add: DiffPart[] = [];

  for (let change of diffWordsWithSpace(before, after)) {
    if (!change.added) {
      del.push({ text: change.value, changed: !!change.removed });
    }

    if (!change.removed) {
      add.push({ text: change.value, changed: !!change.added });
    }
  }

  return { del, add };
}

/**
 * A line diff with word-level marks on lines that were edited rather than
 * replaced, and long unchanged stretches folded down to a few lines of
 * context on either side.
 */
export function diffBodies(before: string, after: string): { rows: DiffRow[]; stats: DiffStats } {
  let rows: DiffRow[] = [];
  let stats: DiffStats = { added: 0, removed: 0 };
  let oldNo = 1;
  let newNo = 1;
  let changes = diffLines(before.endsWith("\n") ? before : before + "\n", after.endsWith("\n") ? after : after + "\n");

  for (let i = 0; i < changes.length; i++) {
    let change = changes[i];
    let lines = splitLines(change.value);

    if (change.removed && changes[i + 1]?.added) {
      let added = splitLines(changes[i + 1].value);
      let pairs = Math.max(lines.length, added.length);
      let dels: DiffRow[] = [];
      let adds: DiffRow[] = [];

      for (let j = 0; j < pairs; j++) {
        let a = lines[j];
        let b = added[j];
        let paired = a !== undefined && b !== undefined;
        let words = paired ? wordParts(a, b) : null;

        if (a !== undefined) {
          dels.push({ id: `d${oldNo}`, kind: "del", oldNo: oldNo++, newNo: null, parts: words?.del ?? [{ text: a, changed: false }] });
        }

        if (b !== undefined) {
          adds.push({ id: `a${newNo}`, kind: "add", oldNo: null, newNo: newNo++, parts: words?.add ?? [{ text: b, changed: false }] });
        }
      }

      stats.removed += dels.length;
      stats.added += adds.length;
      rows.push(...dels, ...adds);
      i++;
      continue;
    }

    for (let line of lines) {
      if (change.added) {
        stats.added++;
        rows.push({ id: `a${newNo}`, kind: "add", oldNo: null, newNo: newNo++, parts: [{ text: line, changed: false }] });
      } else if (change.removed) {
        stats.removed++;
        rows.push({ id: `d${oldNo}`, kind: "del", oldNo: oldNo++, newNo: null, parts: [{ text: line, changed: false }] });
      } else {
        rows.push({ id: `s${oldNo}`, kind: "same", oldNo: oldNo++, newNo: newNo++, parts: [{ text: line, changed: false }] });
      }
    }
  }

  return { rows: fold(rows), stats };
}

function fold(rows: DiffRow[]): DiffRow[] {
  let keep = rows.map((row) => row.kind !== "same");

  rows.forEach((row, i) => {
    if (row.kind !== "same") {
      for (let k = Math.max(0, i - CONTEXT); k <= Math.min(rows.length - 1, i + CONTEXT); k++) {
        keep[k] = true;
      }
    }
  });

  let out: DiffRow[] = [];
  let hidden = 0;

  rows.forEach((row, i) => {
    if (keep[i]) {
      if (hidden > 0) {
        out.push(gapRow(i, hidden));
        hidden = 0;
      }

      out.push(row);
    } else {
      hidden++;
    }
  });

  if (hidden > 0) {
    out.push(gapRow(rows.length, hidden));
  }

  return out;
}

function gapRow(at: number, hidden: number): DiffRow {
  return {
    id: `g${at}`,
    kind: "gap",
    oldNo: null,
    newNo: null,
    parts: [{ text: `${hidden} unchanged line${hidden === 1 ? "" : "s"}`, changed: false }],
  };
}

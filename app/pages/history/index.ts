import { NotFoundError, Request, Response, redirect, session, sql } from "@elements/app";
import { findSpace, listSpaces, pages } from "#app/shared/services/pages";
import html, { Snapshot, VersionItem } from "./template";
import { diffBodies } from "./diff";

function versionParam(value: unknown, fallback: number, latest: number): number {
  let n = Number(value);

  return Number.isInteger(n) && n >= 1 && n <= latest ? n : fallback;
}

export default function route(req: Request, res: Response) {
  if (!session.isLoggedIn()) {
    redirect("/signin");
    return;
  }

  let pageId = req.params.pageId;
  let space = findSpace(req.params.slug);

  if (!space) {
    throw new NotFoundError("no such space");
  }

  let versions = sql<VersionItem>(`
    select v.id, v.version, v.title, v.authorId, u.name as authorName, v.note, v.createdAt
    from pageVersions v
    join pages p on p.id = v.pageId
    left join users u on u.id = v.authorId
    where v.pageId = ${pageId} and p.spaceId = ${space.id}
    order by v.version desc
  `).all();

  if (versions.length === 0) {
    throw new NotFoundError("no such page");
  }

  let latest = versions[0].version;
  let to = versionParam(req.query.to, latest, latest);
  let from = versionParam(req.query.from, Math.max(1, to - 1), latest);

  if (from > to) {
    [from, to] = [to, from];
  }

  let snapshots = sql<Snapshot>(`
    select version, title, body from pageVersions
    where pageId = ${pageId} and version in (${from}, ${to})
  `).all();

  let fromSnap = snapshots.find((s) => s.version === from)!;
  let toSnap = snapshots.find((s) => s.version === to)!;
  let { rows, stats } = diffBodies(fromSnap.body, toSnap.body);

  return new html({
    spaces: listSpaces(),
    space,
    tree: pages.view({ spaceId: space.id }),
    pageId,
    versions,
    comparison: { from: fromSnap, to: toSnap, rows, stats },
    mode: req.query.mode === "read" ? "read" : "changes",
  });
}

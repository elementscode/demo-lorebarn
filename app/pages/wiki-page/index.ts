import { NotFoundError, Request, Response, redirect, session, sql } from "@elements/app";
import { findSpace, listSpaces, pages } from "#app/shared/services/pages";
import { join, leave, listPresent, presence } from "#app/shared/services/presence";
import html, { startDraft } from "./template";

export default function route(req: Request, res: Response) {
  let userId = session.get("userId");

  if (!userId) {
    redirect("/signin");
    return;
  }

  let userName = session.getOrThrow("userName");
  let pageId = req.params.pageId;
  let space = findSpace(req.params.slug);

  if (!space) {
    throw new NotFoundError("no such space");
  }

  let page = sql<{ title: string; body: string; version: number }>(`
    select title, body, version from pages where id = ${pageId} and spaceId = ${space.id}
  `).first();

  if (!page) {
    throw new NotFoundError("no such page");
  }

  let editing = req.query.edit === "1";

  // A three second grace on the way out keeps a reload or a hop to the
  // history page from blinking the user out of everyone else's presence bar.
  let listener = presence.listen({ filter: (e) => e.pageId === pageId })
    .on("connect", (l) => join(l.id, pageId, userId, userName, editing))
    .on("disconnect", (l) => setTimeout(() => leave(l.id, pageId), 3000));

  return new html({
    spaces: listSpaces(),
    space,
    tree: pages.view({ spaceId: space.id }),
    pageId,
    initialDraft: startDraft(page, editing),
    listener,
    users: listPresent(pageId),
  });
}

import { Request, Response, redirect, session, sql } from "@elements/app";
import { pages } from "#app/shared/services/pages";
import html, { SpaceSummary } from "./template";

export default function route(req: Request, res: Response) {
  if (!session.isLoggedIn()) {
    redirect("/signin");
    return;
  }

  let spaces = sql<SpaceSummary>(`
    select s.id, s.slug, s.name, s.description, count(p.id)::int as pageCount
    from spaces s
    left join pages p on p.spaceId = s.id
    group by s.id
    order by s.position, s.name
  `).all();

  return new html({
    spaces,
    recent: pages.view({}, { orderBy: "updatedAt desc", limit: 8 }),
  });
}

import { Request, Response, redirect, session } from "@elements/app";
import { listSpaces } from "#app/shared/services/pages";
import html, { search } from "./template";

export default function route(req: Request, res: Response) {
  if (!session.isLoggedIn()) {
    redirect("/signin");
    return;
  }

  let q = typeof req.query.q === "string" ? req.query.q.trim() : "";

  return new html({ spaces: listSpaces(), q, results: q ? search(q) : [] });
}

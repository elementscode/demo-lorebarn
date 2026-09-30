import { NotFoundError, Request, Response, redirect, session } from "@elements/app";
import { findSpace, listSpaces, pages } from "#app/shared/services/pages";
import html from "./template";

export default function route(req: Request, res: Response) {
  if (!session.isLoggedIn()) {
    redirect("/signin");
    return;
  }

  let space = findSpace(req.params.slug);

  if (!space) {
    throw new NotFoundError("no such space");
  }

  return new html({ spaces: listSpaces(), space, tree: pages.view({ spaceId: space.id }) });
}

import { Request, Response, getAppUrl, redirect, session } from "@elements/app";
import { isUserAdmin } from "#app/shared/services/auth";
import { listSpaces } from "#app/shared/services/pages";
import html, { loadRoster } from "./template";

export default function route(req: Request, res: Response) {
  let userId = session.get("userId");

  if (!userId) {
    redirect("/signin");
    return;
  }

  // A member who follows an old link lands home; the rpc on this page still
  // check the role themselves.
  if (!isUserAdmin(userId)) {
    redirect("/");
    return;
  }

  return new html({ spaces: listSpaces(), initial: loadRoster(), appUrl: getAppUrl() });
}

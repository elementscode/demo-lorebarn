import { Request, Response, redirect, session } from "@elements/app";
import html, { findInvite } from "./template";

export default function route(req: Request, res: Response) {
  if (session.isLoggedIn()) {
    redirect("/");
    return;
  }

  let token = req.params.token;

  return new html({ token, invite: findInvite(token) ?? null });
}

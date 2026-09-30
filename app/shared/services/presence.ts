import { Channel, session, sql } from "@elements/app";
import { hostname } from "node:os";

export interface PresentUser {
  userId: string;
  userName: string;
  editing: boolean;
}

export interface PresenceEvent {
  pageId: string;
  users: PresentUser[];
}

export const presence = new Channel<PresenceEvent>("presence");

export function listPresent(pageId: string): PresentUser[] {
  return sql<PresentUser>(`
    select userId, min(userName) as userName, bool_or(editing) as editing
    from pagePresence
    where pageId = ${pageId}
    group by userId
    order by min(createdAt)
  `).all();
}

/**
 * The list rides in the notification, so a join or an edit toggle costs one
 * query here instead of one per browser watching the page.
 */
function broadcast(pageId: string) {
  presence.notify({ pageId, users: listPresent(pageId) });
}

export function join(listenerId: string, pageId: string, userId: string, userName: string, editing: boolean) {
  sql(`
    insert into pagePresence (listenerId, pageId, userId, userName, editing, host)
         values (${listenerId}, ${pageId}, ${userId}, ${userName}, ${editing}, ${hostname()})
    on conflict (listenerId) do nothing
  `);

  broadcast(pageId);
}

export function leave(listenerId: string, pageId: string) {
  sql(`delete from pagePresence where listenerId = ${listenerId}`);
  broadcast(pageId);
}

/** @rpc */
export function setEditing(pageId: string, editing: boolean) {
  let userId = session.getOrThrow("userId");

  sql(`update pagePresence set editing = ${editing} where pageId = ${pageId} and userId = ${userId}`);
  broadcast(pageId);
}

export function clearThisHost() {
  sql(`delete from pagePresence where host = ${hostname()}`);
}

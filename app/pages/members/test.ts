import { test, assert, equal, sql } from "@elements/app";
import { loginAs, makeUser } from "#app/shared/services/testing";
import { acceptInvite } from "#app/pages/invite/template";
import { sendInvite, setRole } from "./template";

async function threw(fn: () => unknown | Promise<unknown>): Promise<string> {
  try {
    await fn();
  } catch (err: any) {
    return err.message;
  }

  return "";
}

test("members", async () => {
  test("an admin invites, and the invitee joins with that role", async () => {
    let admin = makeUser("Maya", "admin");
    loginAs(admin, "Maya", "admin");

    let roster = sendInvite("  Sam@Example.com ", "member");
    let invite = roster.invites.find((i) => i.email === "sam@example.com");
    assert(invite, roster.invites.map((i) => i.email).join(", "));
    equal(roster.invites.filter((i) => i.email.endsWith("@example.com")).map((i) => i.email), ["sam@example.com"]);

    let token = invite.token;
    acceptInvite(token, "Sam Carter", "longenough");

    let user = sql<{ name: string; role: string }>(`select name, role from users where email = 'sam@example.com'`).firstOrThrow();
    equal(user, { name: "Sam Carter", role: "member" });

    let again = await threw(() => acceptInvite(token, "Sam Again", "longenough"));
    assert(again.includes("already been used"), again);
  });

  test("a member can't invite or change roles", async () => {
    let member = makeUser("Theo");
    loginAs(member, "Theo");

    assert((await threw(() => sendInvite("x@example.com", "member"))).includes("Only admins"));
    assert((await threw(() => setRole(member, "admin"))).includes("Only admins"));
  });

  test("an admin can't demote themselves", async () => {
    let admin = makeUser("Maya", "admin");
    loginAs(admin, "Maya", "admin");

    assert((await threw(() => setRole(admin, "member"))).includes("own admin role"));
  });
});

import { test, assert, equal, session, sql } from "@elements/app";
import { signin } from "#app/shared/services/auth";
import { makeUser } from "#app/shared/services/testing";

test("signin", () => {
  test("the right password signs in with the user's role", () => {
    let id = makeUser("Ada Lovelace", "admin");
    let email = sql<{ email: string }>(`select email from users where id = ${id}`).firstOrThrow().email;

    signin(` ${email.toUpperCase()} `, "password1");

    equal(session.get("userId"), id);
    equal(session.get("role"), "admin");
  });

  test("a wrong password is refused without saying which part was wrong", () => {
    let id = makeUser("Ada Lovelace");
    let email = sql<{ email: string }>(`select email from users where id = ${id}`).firstOrThrow().email;

    try {
      signin(email, "nope");
      assert(false, "expected signin to throw");
    } catch (err: any) {
      assert(err.message.includes("don't match"), err.message);
    }
  });
});

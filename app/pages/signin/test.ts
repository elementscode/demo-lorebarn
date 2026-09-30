import { test, assert, equal, session } from "@elements/app";
import { signin } from "#app/shared/services/auth";
import { makeUser } from "#app/shared/services/testing";

test("signin", () => {
  test("the right password signs in with the user's role", () => {
    let id = makeUser("Ada Lovelace", "admin");

    signin(" Ada.Lovelace@TEST.dev ", "password1");

    equal(session.get("userId"), id);
    equal(session.get("role"), "admin");
  });

  test("a wrong password is refused without saying which part was wrong", () => {
    makeUser("Ada Lovelace");

    try {
      signin("ada.lovelace@test.dev", "nope");
      assert(false, "expected signin to throw");
    } catch (err: any) {
      assert(err.message.includes("don't match"), err.message);
    }
  });
});

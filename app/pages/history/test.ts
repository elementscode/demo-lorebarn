import { test, equal, session, sql } from "@elements/app";
import { pages } from "#app/shared/services/pages";
import { loginAs, makeSpace, makeUser } from "#app/shared/services/testing";
import { diffBodies } from "./diff";
import { restoreVersion } from "./template";

test("history", () => {
  test("diff counts edited lines and marks the changed words", () => {
    let { rows, stats } = diffBodies("a\nprice is $49\nc\n", "a\nprice is $55\nc\nd\n");

    equal(stats, { added: 2, removed: 1 });

    let edited = rows.find((r) => r.kind === "add" && r.newNo === 2)!;
    equal(edited.parts.filter((p) => p.changed).map((p) => p.text), ["55"]);
  });

  test("long unchanged runs fold into a gap", () => {
    let before = Array.from({ length: 30 }, (_, i) => `line ${i}`).join("\n");
    let after = before.replace("line 15", "line fifteen");
    let { rows } = diffBodies(before, after);

    equal(rows.filter((r) => r.kind === "gap").length, 2);
  });

  test("restore writes a new version with a note", () => {
    let ada = makeUser("Ada");
    let spaceId = makeSpace("eng");

    loginAs(ada, "Ada");

    let tree = pages.view({ spaceId });
    let page = tree.insert({ title: "Pricing", body: "old prices", parentId: null });
    tree.update({ ...page, body: "new prices" });

    try {
      restoreVersion(page.id, 1);
    } catch {
      // restoreVersion redirects when it's done, which surfaces here as a throw.
    }

    let now = sql<{ body: string; version: number }>(`select body, version from pages where id = ${page.id}`).firstOrThrow();
    equal(now, { body: "old prices", version: 3 });

    let note = sql<{ note: string }>(`select note from pageVersions where pageId = ${page.id} and version = 3`).firstOrThrow();
    equal(note.note, "Restored from version 1");
    equal(session.get("userId"), ada);
  });
});

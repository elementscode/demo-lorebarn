import { test, assert, equal, errorf, sql } from "@elements/app";
import { buildTree, flattenTree, pages, Page } from "./pages";
import { loginAs, makeSpace, makeUser } from "./testing";

function versions(pageId: string): number[] {
  return sql<{ version: number }>(`select version from pageVersions where pageId = ${pageId} order by version`)
    .all()
    .map((v) => v.version);
}

async function threw(fn: () => unknown | Promise<unknown>): Promise<string> {
  try {
    await fn();
  } catch (err: any) {
    return err.message;
  }

  return "";
}

test("pages", async () => {
  let ada = makeUser("Ada");
  let grace = makeUser("Grace");
  let spaceId = makeSpace("eng");

  test("insert keeps version 1", async () => {
    loginAs(ada, "Ada");

    let tree = pages.view({ spaceId });
    let page = tree.insert({ title: "  Runbook  ", body: "# hi", parentId: null });

    equal(page.title, "Runbook");
    equal(page.version, 1);
    equal(page.updatedByName, "Ada");
    equal(versions(page.id), [1]);
  });

  test("an edit bumps the version and keeps a snapshot", async () => {
    loginAs(ada, "Ada");

    let tree = pages.view({ spaceId });
    let page = tree.insert({ title: "Runbook", body: "one", parentId: null });

    loginAs(grace, "Grace");

    let saved = pages.view({ spaceId }).update({ ...page, body: "two" });

    equal(saved.version, 2);
    equal(saved.updatedByName, "Grace");
    equal(versions(page.id), [1, 2]);

    let snapshot = sql<{ body: string }>(`select body from pageVersions where pageId = ${page.id} and version = 1`).firstOrThrow();
    equal(snapshot.body, "one");
  });

  test("an edit against an old version is refused", async () => {
    loginAs(ada, "Ada");

    let tree = pages.view({ spaceId });
    let page = tree.insert({ title: "Runbook", body: "one", parentId: null });
    let stale: Page = { ...page };

    tree.update({ ...stale, body: "two" });

    let message = await threw(() => pages.view({ spaceId }).update({ ...stale, body: "three" }));

    assert(message.includes("saved version 2"), `expected a conflict, got "${message}"`);
    equal(versions(page.id), [1, 2]);
  });

  test("a move leaves the history alone", async () => {
    loginAs(ada, "Ada");

    let tree = pages.view({ spaceId });
    let parent = tree.insert({ title: "Parent", body: "", parentId: null });
    let child = tree.insert({ title: "Child", body: "", parentId: null });
    let moved = tree.update({ ...child, parentId: parent.id, position: 1 });

    equal(moved.parentId, parent.id);
    equal(moved.version, 1);
    equal(versions(child.id), [1]);
  });

  test("a page can't move under its own subpage", async () => {
    loginAs(ada, "Ada");

    let tree = pages.view({ spaceId });
    let parent = tree.insert({ title: "Parent", body: "", parentId: null });
    let child = tree.insert({ title: "Child", body: "", parentId: parent.id });
    let message = await threw(() => tree.update({ ...parent, parentId: child.id }));

    assert(message.includes("under itself"), `expected a cycle error, got "${message}"`);
  });

  test("a page with subpages can't be deleted", async () => {
    loginAs(ada, "Ada");

    let tree = pages.view({ spaceId });
    let parent = tree.insert({ title: "Parent", body: "", parentId: null });
    tree.insert({ title: "Child", body: "", parentId: parent.id });

    let message = await threw(() => tree.delete(parent));

    assert(message.includes("subpages"), `expected a refusal, got "${message}"`);
    assert(!sql(`select 1 from pages where id = ${parent.id}`).empty(), "parent should still exist");
  });

  test("signed out, nothing can be written", async () => {
    let message = await threw(() => pages.view({ spaceId }).insert({ title: "Nope", body: "", parentId: null }));

    if (!message) {
      errorf("expected an anonymous insert to be refused");
    }
  });

  test("the tree nests and orders siblings by position", async () => {
    let rows = [
      { id: "b", parentId: null, position: 2, title: "B" },
      { id: "a", parentId: null, position: 1, title: "A" },
      { id: "a1", parentId: "a", position: 1, title: "A1" },
      { id: "orphan", parentId: "gone", position: 1, title: "Orphan" },
    ] as Page[];

    let flat = flattenTree(buildTree(rows)).map((n) => `${n.depth}:${n.id}`);

    equal(flat, ["0:a", "1:a1", "0:b"]);
  });
});

import { test, assert, equal } from "@elements/app";
import { pages } from "#app/shared/services/pages";
import { loginAs, makeSpace, makeUser } from "#app/shared/services/testing";
import { search, toPrefixQuery } from "./template";

test("search", () => {
  test("every word becomes a prefix term", () => {
    equal(toPrefixQuery("On-call  runb"), "on:* & call:* & runb:*");
    equal(toPrefixQuery("'; drop table --"), "drop:* & table:*");
    equal(toPrefixQuery("   "), "");
  });

  test("finds pages by title and body with highlighted, escaped snippets", () => {
    let ada = makeUser("Ada");
    let spaceId = makeSpace("eng");

    loginAs(ada, "Ada");

    let tree = pages.view({ spaceId });
    tree.insert({ title: "Rollback runbook", body: "Run the <script>rollback</script> command.", parentId: null });
    tree.insert({ title: "Expenses", body: "Submit receipts within a week.", parentId: null });

    let results = search("rollb").filter((r) => r.spaceSlug === "eng");

    equal(results.map((r) => r.title), ["Rollback runbook"]);
    assert(results[0].titleHtml.includes("<mark>Rollback</mark>"), results[0].titleHtml);
    assert(!results[0].snippetHtml.includes("<script>"), results[0].snippetHtml);

    equal(search("receipts").filter((r) => r.spaceSlug === "eng").map((r) => r.title), ["Expenses"]);
  });
});

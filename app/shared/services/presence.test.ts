import { test, equal } from "@elements/app";
import { join, leave, listPresent } from "./presence";

test("presence", () => {
  test("one entry per person, editing if any of their tabs is", () => {
    let pageId = "01a0f3b8-0000-7000-8000-000000000001";

    join("tab-1", pageId, "01a0f3b8-0000-7000-8000-00000000000a", "Ada", false);
    join("tab-2", pageId, "01a0f3b8-0000-7000-8000-00000000000a", "Ada", true);
    join("tab-3", pageId, "01a0f3b8-0000-7000-8000-00000000000b", "Grace", false);

    equal(listPresent(pageId).map((u) => [u.userName, u.editing]), [["Ada", true], ["Grace", false]]);

    leave("tab-2", pageId);
    leave("tab-3", pageId);

    equal(listPresent(pageId).map((u) => [u.userName, u.editing]), [["Ada", false]]);
  });
});

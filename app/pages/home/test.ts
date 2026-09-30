import { test, equal } from "@elements/app";
import { excerpt, initials, timeAgo } from "#app/shared/services/format";

test("home", () => {
  test("recent items show a short, plain excerpt", () => {
    equal(excerpt("## Setup\n\n**Run** `make dev` first.", 40), "Run make dev first.");
    equal(excerpt("| a | b |\n\nSee [the spec](/s/x) (draft).\n\n- [x] done", 80), "See the spec (draft).");
    equal(initials("Priya Raman"), "PR");
  });

  test("edit times read as relative", () => {
    let now = new Date("2026-09-30T12:00:00Z");

    equal(timeAgo(new Date("2026-09-30T11:59:40Z"), now), "just now");
    equal(timeAgo(new Date("2026-09-30T09:00:00Z"), now), "3h ago");
    equal(timeAgo(new Date("2026-09-29T09:00:00Z"), now), "yesterday");
  });
});

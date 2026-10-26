![A team wiki with version history, built by Claude Code on Elements: editing a page with markdown beside its live preview, the space's page tree, and three teammates on the page with one of them editing.](https://elements.dev/demos/01a0f3c9-6ed3-7a9a-b2c5-64cab23e4672/poster?v=dcea3bd94986)

# A team wiki with version history, built by Claude Code on Elements

> Lorebarn is a full-stack app built with Claude Code on Elements.

Nested pages in markdown with live preview, version diffs and restore, presence on every page, and full-text search.

[Run this app on your machine](https://elements.dev/demos/01a0f3c9-6ed3-7a9a-b2c5-64cab23e4672). Use this demo as inspiration, or as the starting point for your own app. Your agent creates a new app with this one as the scaffold, and you prompt it to add whatever features you want.

## How it's built

Lorebarn needed a page tree that updates for everyone, a version kept on every save, presence on each page, full text search and email invites. Each of those is a part of Elements, so the agent spent its 17 minutes on the wiki itself.

- **Live pages and tree.** Pages are a LiveTable split by space, so a save, a new page or a move in the tree shows up in every open tree, page and home screen at once.

- **A version on every save.** Each edit is checked against the latest version, keeps a snapshot in the same transaction, and tells a late editor who saved first. History restores a version through the same live table, so every open copy updates.

- **Presence.** A channel tracks who is on each page and who is editing, and every open copy of the page shows the same people as they arrive, start typing and leave.

- **Full text search.** Search ranks matches across every page and highlights them, from a weighted search column the migration defines.

- **Invites and roles.** Admins invite members by email and change roles with `@rpc` calls that check for an admin first.

- **Data from SQL files.** Migrations define the wiki and seed one admin, three members, three spaces with 23 nested pages, 64 saved versions and a pending invite.

## Why Elements

Elements is an integrated full-stack app framework and a project server. The project server checks the agent's work as it builds: it type-checks the server and browser code, analyzes the program, applies migrations and runs the tests, then reports the results to the agent. A security mistake, such as calling a server-only function from the browser, is a compile error. The agent reads the report and fixes its own mistakes before it tells you a feature is done. The same checks run on every feature you ask for next.

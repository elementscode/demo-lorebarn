![Lorebarn, a team wiki built with Elements: editing a page with markdown beside its live preview, the space's page tree, and three teammates on the page with one of them editing.](https://elements.dev/demos/01a0f3c9-6ed3-7a9a-b2c5-64cab23e4672/poster?v=dcea3bd94986)

# Lorebarn

> A demo app built with [Elements](https://elements.dev).

Nested pages in markdown with live preview, version diffs and restore, presence on every page, and full-text search.

**Demo:** [Lorebarn](https://elements.dev/demos/01a0f3c9-6ed3-7a9a-b2c5-64cab23e4672)

## Agent specs

What one run of the prompt below took, from an empty Elements project to this
app.

- **Agent:** Claude Code, Opus 5.5 Medium
- **Time:** 17 min
- **Cost:** $5.99 at API rates, September 2026

## Get started

```bash
elements create lorebarn -scaffold=elementscode/demo-lorebarn
```

## How it's built

Lorebarn needed a page tree that updates for everyone, a version kept on every save, presence on each page, full text search and email invites. Each of those is a part of Elements, so the agent spent its 17 minutes on the wiki itself.

### What Elements gave the app

- **Live pages and tree.** `pages` is a LiveTable in `app/shared/services/pages.ts`, partitioned by space. The editor writes straight to it, so a save, a new page or a move in the tree shows up in every open tree, page and home screen at once.
- **Versions in one handler.** The `pages` update handler tells an edit from a move. An edit has to be made against the latest version: it bumps the version and writes a snapshot to `pageVersions` in the same transaction, and a stale save gets a message naming who saved first.
- **Presence on a Channel.** `presence` in `app/shared/services/presence.ts` is a Channel. The page route joins on connect and leaves on disconnect, `setEditing` flips a reader to editor, and each change carries the full list of who is there, so every open copy of the page shows the same people.
- **Search from SQL.** A generated, weighted search column and an index in the schema migration back the `search` rpc on the search page, which ranks matches and highlights them in the results.
- **Data from SQL files.** Two migrations define the wiki and seed one admin, three members, three spaces with 23 nested pages, 64 saved versions and a pending invite.
- **Sessions and roles.** The members page and its `sendInvite`, `revokeInvite` and `setRole` rpcs check for an admin with `requireAdmin`.

### What the project server gave the agent

The project server runs alongside the agent and answers as soon as a file is saved, so every question came back right away: does it type-check, does it build, did the migration apply, do the tests pass. The agent asked 26 times in 17 minutes and kept moving after each answer. Four times the build caught a mistake, among them a LiveView update that left out the `spaceId` partition column and a test callback missing a Promise return type, each with a message that named the fix. It read the manual for each part as it reached it, 43 pages from `recipes/presence` to `livetable/windows`.

### What shipped

The app type-checks with zero errors and all 28 tests pass. Every page was checked on desktop and phone before publishing. The repo was installed fresh from GitHub and run before the demo went live.

Start in `app/shared/services/pages.ts`.

## Demo accounts

The seed writes the wiki of Crewline, a made-up company that makes scheduling
software for field-service shops: three spaces (Engineering, Product,
Handbook) with 23 pages nested up to three levels deep, and 64 saved versions,
two to four per page, so every page has history to compare and restore. One
invite, for sam@lorebarn.dev, is pending.

Every account's password is `lorebarn`, and the sign-in page lists them.

| Email              | Role   |
| ------------------ | ------ |
| maya@lorebarn.dev  | admin  |
| theo@lorebarn.dev  | member |
| priya@lorebarn.dev | member |
| jonah@lorebarn.dev | member |

In development, invite emails are written to `.elements/logs/program.log`
instead of being sent; the Members page also has a "Copy link" button for each
pending invite.

## The prompt

```text
Build a team wiki named lorebarn.

Accounts: admin and member. Admins invite members by email.

- Spaces (Engineering, Product, Handbook), each with a tree of pages that can
  nest.
- Pages are markdown with a live preview while editing.
- Every save keeps a version; see a page's history and the diff between two
  versions, and restore one.
- See who else is viewing or editing a page right now.
- Full text search across all pages.
- Recently edited pages on the home screen.

Seed one admin, three members, three spaces and about twenty pages of
realistic content with history. Show the seeded logins on the sign-in page.

Edits, the page tree and presence update in real time.
```

## License

MIT. See [LICENSE](LICENSE).

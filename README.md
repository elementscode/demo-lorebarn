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

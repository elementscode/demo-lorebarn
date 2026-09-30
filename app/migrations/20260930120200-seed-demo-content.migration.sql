-- seed demo content
/** @env development */

-- users: every password is `lorebarn`

insert into users (email, name, password_hash, role, created_at, updated_at) values
  ('maya@lorebarn.dev', 'Maya Okafor', crypt('lorebarn', gen_salt('bf', 10)), 'admin', now() - interval '60 days', now() - interval '60 days'),
  ('theo@lorebarn.dev', 'Theo Lindqvist', crypt('lorebarn', gen_salt('bf', 10)), 'member', now() - interval '59 days', now() - interval '59 days'),
  ('priya@lorebarn.dev', 'Priya Raman', crypt('lorebarn', gen_salt('bf', 10)), 'member', now() - interval '58 days', now() - interval '58 days'),
  ('jonah@lorebarn.dev', 'Jonah Reyes', crypt('lorebarn', gen_salt('bf', 10)), 'member', now() - interval '44 days', now() - interval '44 days');

insert into invites (email, role, invited_by, created_at)
select 'sam@lorebarn.dev', 'member', id, now() - interval '2 days'
from users where email = 'maya@lorebarn.dev';

insert into spaces (slug, name, description, position, created_at) values
  ('engineering', 'Engineering', 'How we build, ship and run the product.', 0, now() - interval '43 days'),
  ('product', 'Product', 'Roadmaps, specs and what we learned from customers.', 1, now() - interval '43 days'),
  ('handbook', 'Handbook', 'How we work together: people, process and policy.', 2, now() - interval '43 days');

-- pages hold their final content; page_versions below derive the earlier
-- saves from it, and the last statement syncs each page to its latest version

------------------------------------------------------------------------------
-- engineering
------------------------------------------------------------------------------

insert into pages (space_id, parent_id, position, title, body)
select id, null, 1, 'Architecture overview', 'Crewline is a scheduling and dispatch product for field service companies: HVAC, plumbing and electrical shops with 5 to 400 technicians. Dispatchers plan the day on the **web board**, technicians work from the **mobile app**, and customers get SMS updates. This page is the ten-minute tour; the child pages go deeper.

## The big pieces

- **`web`**: the dispatch board, a React app served from CloudFront.
- **`api`**: a TypeScript service (Node 22) behind an ALB. Every client talks to it, including the mobile app.
- **`worker`**: the same codebase as `api`, started with `WORKER=1`. It drains the job queues in Redis.
- **`router`**: route optimization, written in Go. The API calls it synchronously when a dispatcher clicks *Optimize day*.
- **Postgres 16** on RDS, one primary and one read replica. The replica serves reports and exports only.

## Request path

```
mobile / web  ->  ALB  ->  api (ECS, 6 tasks)  ->  Postgres primary
                                  |
                                  +-> Redis (queues, rate limits)
                                  +-> router (ECS, 2 tasks)
```

## Principles

1. **One database.** Services share Postgres rather than keeping their own copies. We split a schema when a team asks, not before.
2. **Queues for anything slow.** SMS, email, PDF invoices and webhooks all go through `worker`. An API request should finish in under 300 ms at p95.
3. **Boring deploys.** Every merge to `main` ships through the same pipeline. See [Local development setup](#) for how to run it all on a laptop.

### What we are changing

The router still reads the whole day''s jobs on every call. Theo is moving it to an incremental model this quarter; until that lands, keep days under 900 jobs per region.
'
from spaces where slug = 'engineering';

insert into pages (space_id, parent_id, position, title, body)
select id, (select id from pages where title = 'Architecture overview'), 1, 'Services map', 'Every deployed service, who owns it, and where it runs. If you add a service, add a row here in the same PR.

## Services

| Service | Language | Runs on | Owner | Pager |
|---|---|---|---|---|
| `api` | TypeScript | ECS, 6 tasks | Theo Lindqvist | `crewline-api` |
| `worker` | TypeScript | ECS, 4 tasks | Theo Lindqvist | `crewline-api` |
| `web` | React | CloudFront + S3 | Jonah Reyes | none |
| `router` | Go 1.23 | ECS, 2 tasks | Maya Okafor | `crewline-router` |
| `sms-gateway` | TypeScript | Lambda | Jonah Reyes | `crewline-api` |

## Queues

The worker listens on four Redis queues. Priorities are fixed; a busy `webhooks` queue never delays an SMS.

1. `sms`: appointment reminders and "technician on the way" texts, sent through our SMS gateway.
2. `email`: invoices and receipts, sent through our email relay.
3. `exports`: CSV and PDF exports. Reads from the replica.
4. `webhooks`: outbound calls to customer integrations, retried 8 times with backoff.

## Third parties

- **SMS gateway** for texts. Account owner: Maya.
- **Email relay** for transactional email.
- **Card processor** for billing. Webhooks land on `POST /billing/events` in `api`.
- **Hosted metrics** for metrics, logs and APM.

### Checking what is running

```bash
aws ecs list-services --cluster crewline-prod
aws ecs describe-services --cluster crewline-prod --services api worker router \
  --query ''services[].{name:serviceName,running:runningCount,desired:desiredCount}''
```
'
from spaces where slug = 'engineering';

insert into pages (space_id, parent_id, position, title, body)
select id, (select id from pages where title = 'Architecture overview'), 2, 'Data model', 'The tables that matter, and the rules that keep them consistent. The source of truth is the migrations folder in the `api` repo; this page explains the *why*.

## Core tables

| Table | One row per | Notes |
|---|---|---|
| `accounts` | customer company | Billing lives here, one billing customer each. |
| `technicians` | person in the field | Belongs to one account, has a home depot. |
| `sites` | service address | Geocoded on insert; `lat`/`lng` are required. |
| `jobs` | visit to a site | The center of everything. See [Job lifecycle states](#). |
| `assignments` | technician on a job | A job can have up to 4 technicians. |

## Rules

- **Every row has an `account_id`**, including join tables. Queries without it fail review.
- **Times are `timestamptz`**, stored in UTC. We convert to the account''s time zone at the edge.
- **Soft delete only on `jobs`**, through `cancelled_at`. Everything else is a real delete.

## Tenancy check

Row-level security is on for every table with an `account_id`. The API sets the account per request:

```sql
set local app.account_id = ''0192f3a4-7c1e-7b20-9d55-3a8f0c6e4b11'';
select count(*) from jobs where scheduled_for::date = current_date;
```

If you see zero rows where you expect some, check that the `set local` ran in the same transaction.

### Sizes, September 2026

The largest account has 1.9 million jobs. The `jobs` table is 41 GB with indexes; the others are under 5 GB each.
'
from spaces where slug = 'engineering';

insert into pages (space_id, parent_id, position, title, body)
select id, (select id from pages where title = 'Data model'), 1, 'Job lifecycle states', 'A job moves through a fixed set of states. The API rejects any transition not listed here, so the mobile app and the web board can never disagree about what happened.

## States

| State | Set by | Meaning |
|---|---|---|
| `draft` | dispatcher | Created but not yet on anyone''s schedule. |
| `scheduled` | dispatcher | Has a time window and at least one technician. |
| `en_route` | technician | Tapped *On my way*. Triggers the customer SMS. |
| `on_site` | technician | Arrived, detected by geofence or tapped by hand. |
| `completed` | technician | Work done, signature captured. |
| `invoiced` | system | Invoice sent through the `email` queue. |
| `cancelled` | dispatcher | Terminal. Sets `cancelled_at`. |

## Allowed transitions

```
draft -> scheduled -> en_route -> on_site -> completed -> invoiced
  \          \            \           \
   +----------+------------+-----------+--> cancelled
```

A completed job cannot be cancelled. To undo work, the dispatcher issues a credit on the invoice instead.

## Where it lives in code

The transition table is `api/src/jobs/transitions.ts`. Add a state there first, then the migration, then the UI.

```ts
export const transitions: Record<JobState, JobState[]> = {
  draft: [''scheduled'', ''cancelled''],
  scheduled: [''en_route'', ''cancelled''],
  en_route: [''on_site'', ''cancelled''],
  on_site: [''completed'', ''cancelled''],
  completed: [''invoiced''],
  invoiced: [],
  cancelled: [],
};
```

### Geofence arrival

The app marks `on_site` automatically when the phone is within **150 m** of the site for 60 seconds. Technicians can still tap *Arrived* by hand.
'
from spaces where slug = 'engineering';

insert into pages (space_id, parent_id, position, title, body)
select id, null, 2, 'On-call', 'We run a single weekly rotation for `api`, `worker` and `router`. It starts Monday at 10:00 Pacific and hands off in the #eng-oncall channel.

## Who is on

| Week of | Primary | Secondary |
|---|---|---|
| Sep 28, 2026 | Theo Lindqvist | Maya Okafor |
| Oct 5, 2026 | Jonah Reyes | Theo Lindqvist |
| Oct 12, 2026 | Maya Okafor | Jonah Reyes |

Swap weeks in the pager app yourself, then post the swap in #eng-oncall.

## What you are expected to do

- **Acknowledge a page within 5 minutes**, business hours or not.
- Keep your laptop and a working hotspot within reach.
- Open an incident channel for anything customer-facing: `/incident open` in chat.
- Write the review within two business days, using the [Incident review template](#).

## Severity

1. **SEV1**: dispatchers cannot load the board, or technicians cannot update jobs. Page the secondary right away.
2. **SEV2**: a feature is broken for many accounts (SMS delayed over 10 minutes, exports failing).
3. **SEV3**: one account affected, or a degraded non-critical path.

### Compensation

Primary on-call gets a $400 stipend per week and a day off after any week with a night page.
'
from spaces where slug = 'engineering';

insert into pages (space_id, parent_id, position, title, body)
select id, (select id from pages where title = 'On-call'), 1, 'Runbook: elevated API errors', 'Use this when the **`api 5xx rate`** monitor fires (threshold: 2% of requests over 5 minutes).

## 1. Confirm it is real

Open the metrics dashboard *API / Overview* and check the error rate by route. A single route at 100% is usually a bad deploy; errors spread across every route is usually the database.

```bash
# recent deploys
gh run list --repo crewline/api --workflow deploy --limit 5
```

## 2. If a deploy went out in the last hour

Roll back first, investigate second.

```bash
./scripts/deploy rollback --service api --to previous
```

The rollback takes about 4 minutes. Post in the incident channel when it starts and when it finishes.

## 3. If the database is the problem

Check connections and long-running queries on the primary:

```sql
select pid, now() - query_start as running_for, state, left(query, 80)
from pg_stat_activity
where state <> ''idle''
order by running_for desc
limit 10;
```

- Over **400 connections**: the pool is leaking. Restart `api` tasks one at a time with `./scripts/ecs restart api --rolling`.
- A query running over **2 minutes**: cancel it with `select pg_cancel_backend(<pid>);`, then find out who ran it.
- Replica lag over 60 seconds only affects exports. Pause the `exports` queue: `./scripts/queue pause exports`.

## 4. If Redis is the problem

Symptoms are timeouts on `POST /jobs/:id/status`. Check memory in the Redis console; above 85%, flush the rate limiter keys:

```bash
redis-cli -h $REDIS_HOST --scan --pattern ''rl:*'' | xargs redis-cli -h $REDIS_HOST unlink
```

### After it is over

Open a review from the [Incident review template](#) and link it in #eng-oncall.
'
from spaces where slug = 'engineering';

insert into pages (space_id, parent_id, position, title, body)
select id, (select id from pages where title = 'On-call'), 2, 'Incident review template', 'Copy this page into a new child of *On-call* named `Incident YYYY-MM-DD: short summary`. Reviews are blameless: describe what the system and the process allowed, not who slipped.

## Summary

Two or three sentences: what broke, for whom, for how long.

## Impact

| Measure | Value |
|---|---|
| Duration | e.g. 38 minutes |
| Accounts affected | e.g. 112 of 1,340 |
| Failed requests | e.g. 21,400 |
| SMS delayed | e.g. 3,900, max delay 26 minutes |

## Timeline

All times Pacific. Start with the first signal, not the first page.

- **09:12** Deploy `api@4f2c1e9` finishes.
- **09:14** 5xx monitor fires, Theo acknowledges.
- **09:19** Rollback started.
- **09:23** Error rate back under 0.5%.

## What went well

## What went wrong

## Action items

Each item gets an owner and a date. Track them in the issue tracker with the `incident` label.

| Action | Owner | Due |
|---|---|---|
| Add a canary step to the deploy | Theo Lindqvist | Oct 9, 2026 |

### Sharing it

Post the link in #eng-oncall and read it aloud at the Thursday engineering sync.
'
from spaces where slug = 'engineering';

insert into pages (space_id, parent_id, position, title, body)
select id, null, 3, 'Local development setup', 'From a fresh laptop to a running board in about 30 minutes. If a step fails, fix this page in the same sitting.

## Prerequisites

- macOS 14 or later, with Homebrew
- **Docker Desktop** (for Postgres and Redis)
- Access to the `crewline` GitHub org and the `dev` AWS account. Ask Maya if either is missing.

## 1. Clone and install

```bash
git clone git@github.com:crewline/api.git
git clone git@github.com:crewline/web.git
brew install node@22 go@1.23 direnv
cd api && npm ci
```

## 2. Start the databases

```bash
docker compose up -d postgres redis
npm run db:migrate
npm run db:seed -- --accounts 3 --jobs 500
```

The seed creates three demo accounts. Sign in as `dispatch@demo.crewline.dev` with password `crewline-dev`.

## 3. Run everything

```bash
npm run dev          # api on :4000, worker in the same process
cd ../web && npm run dev   # board on :5173
```

The router is optional locally. Without it, *Optimize day* returns the jobs in time order.

## Common problems

| Symptom | Fix |
|---|---|
| `ECONNREFUSED 5432` | Docker is not running, or another Postgres holds the port. `lsof -i :5432` |
| Board loads with no jobs | The seed ran against a different database. Check `DATABASE_URL` in `.envrc`. |
| `direnv: error .envrc is blocked` | Run `direnv allow` in the repo. |

### Mobile app

The React Native app needs Xcode 16. See the README in `crewline/mobile`; it points at your local API through `API_URL=http://<your-lan-ip>:4000`.
'
from spaces where slug = 'engineering';

------------------------------------------------------------------------------
-- product
------------------------------------------------------------------------------

insert into pages (space_id, parent_id, position, title, body)
select id, null, 1, '2026 Q4 roadmap', 'What we are building from October through December 2026, in priority order. Owners update status every Friday. Questions go to Priya.

## Themes

1. **Win bigger shops.** Accounts over 50 technicians churn half as often, but they need SSO and exports before they sign.
2. **Fewer calls to dispatch.** Every "where is my technician?" call costs a shop about 4 minutes.
3. **Get paid faster.** Median time from `completed` to paid is 11 days. We want 6.

## Committed

| Project | Theme | Owner | Target | Status |
|---|---|---|---|---|
| [Spec: SSO for teams](#) | Win bigger shops | Theo Lindqvist | Nov 13 | In build |
| [Spec: bulk export](#) | Win bigger shops | Jonah Reyes | Oct 30 | In build |
| Live ETA link in SMS | Fewer calls | Jonah Reyes | Nov 20 | Design |
| Card on file at booking | Get paid faster | Priya Raman | Dec 11 | Discovery |

## Stretch

- Recurring maintenance plans (quarterly filter changes, annual inspections)
- Two-way sync with accounting software

## Not this quarter

- **Inventory tracking.** Asked for often, but it is a product of its own. Revisit in Q2 2027.
- A native Android tablet layout.

### How we measure it

We will call the quarter a success if at least **8 accounts over 50 technicians** sign, and median time-to-paid drops under 8 days.
'
from spaces where slug = 'product';

insert into pages (space_id, parent_id, position, title, body)
select id, null, 2, 'Specs', 'Every feature bigger than a week of work gets a spec here before build starts. A spec is a decision record, not a design doc: it says what we are building, for whom, and what we chose not to do.

## How to write one

1. Create a child page named `Spec: <feature>`.
2. Fill in the sections below. Keep it under two screens.
3. Tag the engineering owner and post the link in #product.
4. Review happens async for three business days, then Priya marks it **Approved** in the header.

## Sections every spec has

- **Problem**: who is hurting and how we know. Link interviews.
- **Proposal**: what the user sees, step by step.
- **Out of scope**: what we are deliberately not doing.
- **Rollout**: flags, which accounts first, how we know it worked.
- **Open questions**: with an owner for each.

## Status

| Spec | Owner | Status |
|---|---|---|
| Spec: bulk export | Priya Raman | Approved |
| Spec: SSO for teams | Priya Raman | Approved |
| Live ETA link | Jonah Reyes | Draft |

### Tips

Screenshots of a rough mockup beat paragraphs. If the spec needs a diagram of states, link the engineering page instead of redrawing it.
'
from spaces where slug = 'product';

insert into pages (space_id, parent_id, position, title, body)
select id, (select id from pages where title = 'Specs'), 1, 'Spec: bulk export', '**Status:** Approved Sep 19, 2026. **Owner:** Priya Raman. **Engineering:** Jonah Reyes.

## Problem

Office managers at larger shops export jobs every month for payroll and for their accountant. Today they page through the board and copy rows by hand. In interviews, 7 of 9 shops over 50 technicians named this as a reason they hesitated to sign. See [Interview notes: Northwind](#).

## Proposal

- A new **Export** button on the Jobs list, respecting the current filters.
- Formats: **CSV** and **XLSX**. PDF is out of scope.
- Exports run in the background on the `exports` queue. The user gets an email with a download link, valid for 7 days.
- Columns: job number, site address, customer, technicians, scheduled window, state, invoice total, completed at.

## Limits

| Plan | Rows per export | Exports per day |
|---|---|---|
| Starter | 10,000 | 5 |
| Growth | 250,000 | 20 |
| Enterprise | 2,000,000 | unlimited |

## Out of scope

- Scheduled, recurring exports. We will see if people ask.
- Exporting technicians or customers. Jobs only for now.

## Rollout

Behind the `bulk_export` flag. Enabled for Northwind and three other design partners on Oct 16, everyone on Oct 30.

### Open questions

- Should the download link require sign-in? **Owner:** Theo. Leaning yes.
'
from spaces where slug = 'product';

insert into pages (space_id, parent_id, position, title, body)
select id, (select id from pages where title = 'Specs'), 2, 'Spec: SSO for teams', '**Status:** Approved Sep 22, 2026. **Owner:** Priya Raman. **Engineering:** Theo Lindqvist.

## Problem

Shops over 50 technicians run Google Workspace or Microsoft Entra, and their IT contractors will not approve a tool that keeps its own passwords. We lost two deals in August over this, worth **$38,400 ARR** together.

## Proposal

- Admins connect an identity provider from *Settings > Security*.
- Supported: **SAML 2.0** (Entra, Okta, JumpCloud) and **Google OIDC**.
- After connecting, admins can require SSO for everyone except one break-glass owner account.
- New users who sign in through SSO are created as technicians by default. Admins can change the default role.

## Out of scope

- SCIM provisioning. Planned for Q1 2027.
- Per-group role mapping.

## Pricing

SSO is included on **Enterprise** and available as a $4 per seat add-on on Growth. See [Pricing](#).

## Rollout

| Date | Step |
|---|---|
| Oct 23 | Internal: we sign in to Crewline with our own company login |
| Nov 3 | Two design partners on Entra |
| Nov 13 | General availability |

### Open questions

Tracked on [SSO rollout plan](#).
'
from spaces where slug = 'product';

insert into pages (space_id, parent_id, position, title, body)
select id, (select id from pages where title = 'Spec: SSO for teams'), 1, 'SSO rollout plan', 'The working checklist for shipping [Spec: SSO for teams](#). Theo owns it until GA on Nov 13.

## Milestones

- [x] Pick a SAML library: `@node-saml/node-saml` 5.x
- [x] Settings screen designs signed off (Sep 24)
- [ ] Internal dogfood on our own company login (Oct 23)
- [ ] Design partners: Northwind Mechanical and Harbor Electric (Nov 3)
- [ ] Support article and in-app announcement (Nov 10)

## Open questions

| Question | Owner | Answer |
|---|---|---|
| What happens to active sessions when SSO becomes required? | Theo | Signed out within 15 minutes, on next API call. |
| Do technicians on shared tablets need SSO? | Priya | No. Tablet PIN login stays. |
| Who can disable SSO if the IdP breaks? | Maya | The break-glass owner, plus Crewline support with two approvals. |

## Test accounts

We have sandbox tenants for each provider. Credentials are in the password manager under *SSO sandboxes*.

```text
Okta:    crewline-dev.okta.com
Entra:   crewlinetest.onmicrosoft.com
Google:  sso-test.crewline.dev
```

### Support readiness

Support gets a 30-minute walkthrough on Nov 6. Jonah is recording it.
'
from spaces where slug = 'product';

insert into pages (space_id, parent_id, position, title, body)
select id, null, 3, 'Customer interviews', 'We talk to at least **four customers a month**, and anyone at the company can join. Notes go here as child pages named `Interview notes: <company>`.

## How to run one

1. Book 30 minutes through the #customer-calls channel. Priya keeps the list of shops who have agreed to talk.
2. Two people per call: one asks, one takes notes.
3. Ask about the last time something happened, not what they would want. "Walk me through last Tuesday" beats "would you use X?"
4. Publish notes within 24 hours, raw is fine.

## Questions we keep coming back to

- How do you plan tomorrow''s schedule, and when?
- What made your last customer call the office?
- What do you do at the end of the month for payroll?
- What would make you switch away from Crewline?

## Recent interviews

| Company | Size | Date | Who talked |
|---|---|---|---|
| Northwind Mechanical | 64 technicians | Sep 3, 2026 | Priya, Maya |
| Harbor Electric | 22 technicians | Sep 10, 2026 | Priya, Jonah |
| Blue Ridge Plumbing | 9 technicians | Sep 17, 2026 | Priya |

### Recording

Ask before recording. We keep recordings for 90 days in the shared recordings folder, then delete them.
'
from spaces where slug = 'product';

insert into pages (space_id, parent_id, position, title, body)
select id, (select id from pages where title = 'Customer interviews'), 1, 'Interview notes: Northwind', '**Date:** Sep 3, 2026. **Company:** Northwind Mechanical, HVAC, 64 technicians across 3 depots. **Talked to:** Dana Whitfield (operations manager). **Crewline:** Priya Raman, Maya Okafor.

## Context

Customer since March 2025, on the Growth plan. Considering Enterprise, and comparing us against keeping their old system for the Tacoma depot.

## What we heard

- Dispatch plans the next day between **3 and 5 pm**. Dana said the board is "the best part, by a mile."
- At month end, their office manager spends **about two days** copying completed jobs into a spreadsheet for payroll. This is the biggest pain by far.
- Their IT contractor asked twice about "logging in with Microsoft". They use Entra for email.
- Technicians forget to tap *On my way*, so customers do not get the SMS and call the office.

> "If I could hit one button and get last month''s jobs into Excel, I''d sign the bigger plan tomorrow." (Dana)

## What we are doing about it

| Heard | Action | Where |
|---|---|---|
| Month-end payroll export | Bulk export, Oct 30 | [Spec: bulk export](#) |
| Microsoft login | SSO, Nov 13 | [Spec: SSO for teams](#) |
| Missed *On my way* taps | Geofence reminders, Q1 | Backlog |

### Follow-up

Priya sends the bulk export beta invite on Oct 16. Dana agreed to a 20-minute call after their October payroll run.
'
from spaces where slug = 'product';

insert into pages (space_id, parent_id, position, title, body)
select id, null, 4, 'Pricing', 'Current list prices, effective **Jul 1, 2026**. Sales can discount up to 15% on annual plans without approval; anything more goes to Maya.

## Plans

| Plan | Per technician / month | Minimum | Includes |
|---|---|---|---|
| Starter | $29 | 3 seats | Board, mobile app, SMS reminders |
| Growth | $49 | 10 seats | Everything in Starter, invoicing, route optimization |
| Enterprise | $79 | 50 seats | Everything in Growth, SSO, exports, priority support |

Annual billing takes **two months off**. Dispatchers and office staff are free; we only charge for technicians.

## Add-ons

- **SMS over 500 per technician per month**: $0.02 per message.
- **SSO on Growth**: $4 per seat.
- **Extra depots** beyond three: $50 per depot per month.

## Rules of thumb

1. Never quote a price that is not on this page. If a deal needs something new, bring it to #pricing.
2. Trials are 14 days, full Growth features, no card.
3. Nonprofits and trade schools get 30% off. Ask for the paperwork.

### Changes under discussion

Priya is testing a per-job price for seasonal shops that run 3 technicians in winter and 15 in summer. No decision before Nov 2026.
'
from spaces where slug = 'product';

------------------------------------------------------------------------------
-- handbook
------------------------------------------------------------------------------

insert into pages (space_id, parent_id, position, title, body)
select id, null, 1, 'Welcome to the team', 'Welcome to Crewline. We are 41 people building the tool that field service shops use to run their day. About a third of us have worked in the trades or alongside them, and it shows in the product.

## What we believe

- **The technician''s time is the product.** Every minute we save them is a minute they can bill.
- **Write it down.** This wiki is how we remember decisions. If you explained something twice, it belongs here.
- **Small teams, clear owners.** Every project has one name next to it.

## How we are organized

| Team | Lead | People |
|---|---|---|
| Engineering | Maya Okafor | 14 |
| Product and design | Priya Raman | 6 |
| Customer success | Luis Ortega | 9 |
| Sales | Ana Pereira | 8 |
| Operations and people | Maya Okafor (interim) | 4 |

## Where things happen

- **Chat** for anything quick. #general for company news, #random for everything else.
- **This wiki** for anything someone will need next month.
- **The issue tracker** for engineering and product work.
- **All-hands** every other Thursday at 11:00 Pacific. Recordings are in the shared drive.

### Start here

Read [Your first week](#) next. Your manager and your onboarding buddy will walk you through the rest.
'
from spaces where slug = 'handbook';

insert into pages (space_id, parent_id, position, title, body)
select id, (select id from pages where title = 'Welcome to the team'), 1, 'Your first week', 'Your first week is for learning, not shipping. Nobody expects a pull request or a closed deal by Friday.

## Day by day

| Day | What happens |
|---|---|
| Monday | Laptop pickup or delivery, accounts, 1:1 with your manager, lunch with your buddy. |
| Tuesday | Product walkthrough with Priya. Set up your tools using the [Accounts and tools checklist](#). |
| Wednesday | Ride along: shadow a customer success call and watch a dispatcher plan a day. |
| Thursday | All-hands (or the recording). Meet one person from each team. |
| Friday | Retro with your manager: what was confusing, what this page got wrong. |

## Your buddy

Everyone gets an onboarding buddy from another team. They are your first stop for "is this normal?" questions. Jonah Reyes started on Aug 17 and has already volunteered for the next two engineering hires.

## The ride-along

Once in your first month, you spend half a day with a customer''s technician. We cover travel, and you wear the boots we send you. It is the fastest way to understand why the app works the way it does.

## Things people wish they had known

- Most meetings are optional in week one. Decline freely.
- Ask in public channels. Someone else has the same question.
- Customer names in chat are fine; customer data in chat is not. See [Security basics](#).
'
from spaces where slug = 'handbook';

insert into pages (space_id, parent_id, position, title, body)
select id, (select id from pages where title = 'Your first week'), 1, 'Accounts and tools checklist', 'Work down this list on your first Tuesday. Anything you cannot get into, post in #it-help and tag Maya.

## Everyone

- [ ] **Work email**: email, calendar and the shared drive. Set up 2-step verification before anything else.
- [ ] **Password manager**: accept the invite, install the browser extension.
- [ ] **Chat**: join #general, #random, #customer-calls and your team channel.
- [ ] **Lorebarn**: this wiki. Sign in with your work email.
- [ ] **Rippling**: payroll, benefits and time off.
- [ ] **Crewline demo account**: so you can use the product like a customer.

## Engineering

- [ ] GitHub, added to the `crewline` org with your personal account
- [ ] AWS SSO, `dev` account only for the first month
- [ ] Metrics dashboard and pager app
- [ ] Issue tracker, *Engineering* team
- [ ] Run through [Local development setup](#)

## Customer-facing teams

- [ ] CRM
- [ ] Support inbox, with your photo on your profile
- [ ] Gong for call recordings

## Hardware

| Role | Laptop | Extras |
|---|---|---|
| Engineering | 14" laptop, 36 GB | Test phones on request |
| Everyone else | 13" laptop, 16 GB | Headset |

Monitors, chairs and desks come out of your home office budget. See [Remote work](#).
'
from spaces where slug = 'handbook';

insert into pages (space_id, parent_id, position, title, body)
select id, null, 2, 'Time off and holidays', 'Rest is part of the job. We would rather you take the time than burn out in March.

## Vacation

- **Minimum 20 days a year**, and we mean minimum. Managers get a nudge if someone on their team has taken fewer than 10 days by September.
- There is no maximum, within reason and with your team''s coverage in place.
- Book it in **Rippling** and put it on the shared *Out of office* calendar.
- For more than 5 consecutive working days, give your manager 3 weeks notice.

## Company holidays, 2026

| Date | Holiday |
|---|---|
| Nov 26-27 | Thanksgiving |
| Dec 24-Jan 1 | Winter break, office closed |

Earlier 2026 holidays are in Rippling. Outside the US, take your local public holidays instead of the US ones, same count.

## Sick days

Take them. You do not need a doctor''s note. Post "out sick" in your team channel and log it in Rippling when you are back.

## Parental leave

**16 weeks fully paid** for every parent, taken in one block or split over the first year. Talk to Maya about the plan at least two months ahead when you can.

### On-call and time off

If you are on the [On-call](#) rotation, swap your week before you book. You are not expected to carry a pager on vacation.
'
from spaces where slug = 'handbook';

insert into pages (space_id, parent_id, position, title, body)
select id, null, 3, 'Expenses', 'Spend company money the way you would spend your own when it is for something you need to do the job well. You do not need approval for anything on this page under the limits listed.

## What we cover

| Category | Limit | Notes |
|---|---|---|
| Home office setup | $1,200 once, then $400 a year | Desk, chair, monitor, lighting |
| Internet | $80 a month | Submit one receipt a quarter |
| Books and courses | $1,000 a year | Talk to your manager above that |
| Customer travel | Economy, reasonable hotel | Book through Navan |
| Team meals | $60 per person | When at least 3 of us are together |

## How to submit

1. Pay with your company card if you have one, otherwise your own card.
2. Snap the receipt in the **expense app** within 7 days. Add a one-line reason.
3. Personal-card expenses are reimbursed on the next payroll.

```text
Good reason: "Ride-along with Harbor Electric, Tacoma, Sep 18"
Bad reason:  "travel"
```

## What we do not cover

- Alcohol, except at company-hosted events
- Upgrades to business class
- Fines, including parking tickets on a customer visit

### Questions

Ask in #ops. Maya reviews expenses every Monday and will reach out if something looks off, which is not the same as being in trouble.
'
from spaces where slug = 'handbook';

insert into pages (space_id, parent_id, position, title, body)
select id, null, 4, 'Remote work', 'Crewline is remote-first. We have a small office in Portland that anyone can use, but nobody is expected to.

## Working hours

- Our **core hours are 10:00 to 14:00 Pacific**. Be reachable on chat then, unless you are on leave or out for the afternoon.
- Outside core hours, work when it suits you. Nobody needs to see a green dot.
- Put your hours in your chat profile so people in other time zones know when to expect you.

## Where you can work from

| Situation | Okay? |
|---|---|
| Home, anywhere in a country where we can employ you | Yes |
| Traveling for up to 4 weeks in another country | Yes, tell Maya first |
| Moving to a new country | Talk to Maya before you decide, payroll takes months |
| Coffee shop, customer calls | Yes, with a headset |

## Getting together

We meet in person **twice a year** for three days, usually Portland in the spring and somewhere new in the fall. The fall 2026 offsite is in **Denver, Oct 20-22**. Travel is booked through Navan and paid by the company.

## Communication norms

1. Default to written and async. A good chat thread beats a meeting.
2. Cameras on for 1:1s, optional for anything bigger.
3. If a thread goes past 20 replies, summarize it on a page here and link it.

### Home office

See [Expenses](#) for the home office budget and internet stipend.
'
from spaces where slug = 'handbook';

insert into pages (space_id, parent_id, position, title, body)
select id, null, 5, 'Security basics', 'We hold the schedules, addresses and payment details of about 1.3 million homeowners. Our customers trust us with that, so these rules are not optional.

## Accounts

- **2-step verification on everything** that supports it. Use a security key or an authenticator app, not SMS.
- Every password lives in the **password manager**. If you type a password from memory, it is probably too short.
- Never share an account. If you need access, ask for your own.

## Customer data

1. Do not copy customer data out of production. For debugging, use the `support-view` tool, which masks phone numbers and addresses.
2. Never paste customer data into chat, email or an AI tool. Link to the record instead.
3. Exports for a customer go through the product, never a manual query.

## Devices

| Requirement | How we check |
|---|---|
| Disk encryption on | Kandji |
| Screen locks after 5 minutes | Kandji |
| OS updates within 14 days | Kandji reminds you, then Maya does |

## If something looks wrong

Report it in **#security** or directly to Theo. A phishing email, a lost laptop, a query you ran against the wrong database: tell us within the hour. Nobody gets in trouble for reporting, only for hiding it.

```text
Lost laptop? Post in #security, then run through the "Lost device" steps
pinned there. We can wipe it remotely within minutes.
```

### Training

Everyone completes the 25-minute security course in their first two weeks, and a refresher every September.
'
from spaces where slug = 'handbook';

------------------------------------------------------------------------------
-- history: version N is the page as it stands; earlier versions undo edits
------------------------------------------------------------------------------

-- Architecture overview
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (
  select replace(p.body, E'\n### What we are changing\n\nThe router still reads the whole day''s jobs on every call. Theo is moving it to an incremental model this quarter; until that lands, keep days under 900 jobs per region.\n', '') as b2
) x
cross join lateral (values
  (1, p.title, replace(replace(x.b2, 'Postgres 16** on RDS, one primary and one read replica', 'Postgres 15** on RDS, one primary and one read replica'), 'api (ECS, 6 tasks)', 'api (ECS, 4 tasks)'), 'maya', '41 days 2 hours', ''),
  (2, p.title, x.b2, 'theo', '30 days 5 hours', ''),
  (3, p.title, p.body, 'maya', '12 days 3 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Architecture overview';

-- Services map
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (
  select regexp_replace(p.body, E'\n### Checking what is running.*$', '') as b2
) x
cross join lateral (values
  (1, p.title, replace(replace(x.b2, E'| `sms-gateway` | TypeScript | Lambda | Jonah Reyes | `crewline-api` |\n', ''), '| `worker` | TypeScript | ECS, 4 tasks |', '| `worker` | TypeScript | ECS, 2 tasks |'), 'theo', '40 days 1 hour', ''),
  (2, p.title, x.b2, 'maya', '26 days 4 hours', ''),
  (3, p.title, p.body, 'theo', '2 days 3 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Services map';

-- Data model
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (values
  (1, p.title, replace(regexp_replace(p.body, E'\n## Tenancy check.*?(?=\n### )', ''), 'The largest account has 1.9 million jobs. The `jobs` table is 41 GB', 'The largest account has 1.6 million jobs. The `jobs` table is 34 GB'), 'theo', '39 days 6 hours', ''),
  (2, p.title, p.body, 'maya', '21 days 1 hour', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Data model';

-- Job lifecycle states
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (
  select replace(p.body, 'within **150 m** of the site', 'within **200 m** of the site') as b3
) x
cross join lateral (
  select regexp_replace(x.b3, E'\n### Geofence arrival.*$', '') as b2
) y
cross join lateral (values
  (1, p.title, replace(y.b2, E'\nA completed job cannot be cancelled. To undo work, the dispatcher issues a credit on the invoice instead.\n', ''), 'theo', '35 days 2 hours', ''),
  (2, p.title, y.b2, 'priya', '18 days 7 hours', ''),
  (3, p.title, x.b3, 'maya', '9 days 4 hours', ''),
  (4, p.title, p.body, 'theo', '1 day 5 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Job lifecycle states';

-- On-call
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (values
  (1, p.title, replace(replace(p.body, 'Primary on-call gets a $400 stipend per week', 'Primary on-call gets a $300 stipend per week'), '| Oct 12, 2026 | Maya Okafor | Jonah Reyes |', '| Oct 12, 2026 | Maya Okafor | Theo Lindqvist |'), 'maya', '38 days 3 hours', ''),
  (2, p.title, p.body, 'theo', '15 days 2 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'On-call';

-- Runbook: elevated API errors
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (
  select replace(p.body, 'Over **400 connections**', 'Over **300 connections**') as b3
) x
cross join lateral (
  select regexp_replace(x.b3, E'\n## 4\\. If Redis is the problem.*?(?=\n### )', '') as b2
) y
cross join lateral (values
  (1, p.title, replace(y.b2, E'\nThe rollback takes about 4 minutes. Post in the incident channel when it starts and when it finishes.\n', ''), 'theo', '33 days 4 hours', ''),
  (2, p.title, y.b2, 'maya', '22 days 6 hours', ''),
  (3, p.title, x.b3, 'theo', '6 days 2 hours', ''),
  (4, p.title, p.body, 'maya', '20 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Runbook: elevated API errors';

-- Incident review template
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (values
  (1, p.title, replace(replace(p.body, E'| SMS delayed | e.g. 3,900, max delay 26 minutes |\n', ''), 'Reviews are blameless: describe', 'Reviews are blamless: describe'), 'maya', '31 days 5 hours', ''),
  (2, p.title, p.body, 'priya', '14 days 3 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Incident review template';

-- Local development setup (renamed from "Dev environment setup")
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (
  select replace(p.body, E'| `direnv: error .envrc is blocked` | Run `direnv allow` in the repo. |\n', '') as b2
) x
cross join lateral (values
  (1, 'Dev environment setup', replace(replace(x.b2, 'brew install node@22 go@1.23 direnv', 'brew install node@20 go@1.22 direnv'), 'in about 30 minutes', 'in about an hour'), 'theo', '40 days 6 hours', ''),
  (2, 'Dev environment setup', x.b2, 'jonah', '28 days 2 hours', ''),
  (3, p.title, p.body, 'theo', '8 days 1 hour', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Local development setup';

-- 2026 Q4 roadmap
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (
  select replace(p.body, '| Theo Lindqvist | Nov 13 | In build |', '| Theo Lindqvist | Nov 13 | Spec review |') as b3
) x
cross join lateral (
  select replace(x.b3, E'- **Inventory tracking.** Asked for often, but it is a product of its own. Revisit in Q2 2027.\n', E'- Inventory tracking\n') as b2
) y
cross join lateral (values
  (1, p.title, replace(replace(y.b2, E'- Two-way sync with accounting software\n', ''), 'at least **8 accounts over 50 technicians**', 'at least **10 accounts over 50 technicians**'), 'priya', '37 days 1 hour', ''),
  (2, p.title, y.b2, 'maya', '24 days 3 hours', ''),
  (3, p.title, x.b3, 'priya', '10 days 5 hours', ''),
  (4, p.title, p.body, 'priya', '1 day 2 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = '2026 Q4 roadmap';

-- Specs
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (values
  (1, p.title, replace(replace(p.body, E'| Live ETA link | Jonah Reyes | Draft |\n', ''), '| Spec: SSO for teams | Priya Raman | Approved |', '| Spec: SAML SSO | Priya Raman | In review |'), 'priya', '36 days 3 hours', ''),
  (2, p.title, p.body, 'theo', '20 days 2 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Specs';

-- Spec: bulk export
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (
  select replace(replace(p.body, '**Status:** Approved Sep 19, 2026.', '**Status:** In review.'), '| Growth | 250,000 | 20 |', '| Growth | 100,000 | 20 |') as b2
) x
cross join lateral (values
  (1, p.title, replace(regexp_replace(x.b2, E'\n## Limits.*?(?=\n## Out of scope)', ''), 'Formats: **CSV** and **XLSX**. PDF is out of scope.', 'Formats: **CSV** only to start.'), 'priya', '34 days 2 hours', ''),
  (2, p.title, x.b2, 'theo', '25 days 1 hour', ''),
  (3, p.title, p.body, 'priya', '11 days 6 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Spec: bulk export';

-- Spec: SSO for teams (renamed from "Spec: SAML SSO")
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (
  select replace(replace(p.body, '**Status:** Approved Sep 22, 2026.', '**Status:** In review.'), E'### Open questions\n\nTracked on [SSO rollout plan](#).\n', E'### Open questions\n\n- What happens to active sessions when SSO becomes required? **Owner:** Theo.\n- Do technicians on shared tablets need SSO? **Owner:** Priya.\n') as b2
) x
cross join lateral (values
  (1, 'Spec: SAML SSO', replace(replace(x.b2, 'Supported: **SAML 2.0** (Entra, Okta, JumpCloud) and **Google OIDC**.', 'Supported: **SAML 2.0** (Entra, Okta, JumpCloud).'), 'worth **$38,400 ARR** together', 'worth about **$35,000 ARR** together'), 'priya', '32 days 4 hours', ''),
  (2, 'Spec: SAML SSO', x.b2, 'theo', '19 days 5 hours', ''),
  (3, p.title, p.body, 'priya', '5 days 3 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Spec: SSO for teams';

-- SSO rollout plan
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (values
  (1, p.title, replace(replace(p.body, '- [x] Settings screen designs signed off (Sep 24)', '- [ ] Settings screen designs signed off (Sep 24)'), '| Who can disable SSO if the IdP breaks? | Maya | The break-glass owner, plus Crewline support with two approvals. |', '| Who can disable SSO if the IdP breaks? | Maya | Open |'), 'theo', '16 days 4 hours', ''),
  (2, p.title, p.body, 'priya', '3 days 4 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'SSO rollout plan';

-- Customer interviews
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (values
  (1, p.title, replace(replace(p.body, E'| Blue Ridge Plumbing | 9 technicians | Sep 17, 2026 | Priya |\n', ''), 'We talk to at least **four customers a month**', 'We talk to at least **two customers a month**'), 'priya', '36 days 5 hours', ''),
  (2, p.title, p.body, 'jonah', '13 days 2 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Customer interviews';

-- Interview notes: Northwind
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (
  select regexp_replace(p.body, E'\n## What we are doing about it.*?(?=\n### )', '') as b2
) x
cross join lateral (values
  (1, p.title, replace(x.b2, 'office manager spends **about two days** copying', 'office manager spends **about two days** coping'), 'priya', '27 days 3 hours', ''),
  (2, p.title, x.b2, 'priya', '26 days 20 hours', ''),
  (3, p.title, p.body, 'maya', '17 days 2 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Interview notes: Northwind';

-- Pricing (version 3 tried new prices, version 4 restored version 2)
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (values
  (1, p.title, replace(regexp_replace(p.body, E'\n### Changes under discussion.*$', ''), '- **Extra depots** beyond three: $50 per depot per month.', '- **Extra depots**: $50 per depot per month.'), 'priya', '41 days 8 hours', ''),
  (2, p.title, p.body, 'maya', '29 days 1 hour', ''),
  (3, p.title, replace(replace(p.body, '| Growth | $49 | 10 seats |', '| Growth | $55 | 10 seats |'), '| Enterprise | $79 | 50 seats |', '| Enterprise | $89 | 50 seats |'), 'priya', '23 days 4 hours', ''),
  (4, p.title, p.body, 'maya', '7 days 2 hours', 'Restored from version 2')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Pricing';

-- Welcome to the team
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (
  select replace(replace(p.body, 'We are 41 people building', 'We are 38 people building'), '| Customer success | Luis Ortega | 9 |', '| Customer success | Luis Ortega | 7 |') as b2
) x
cross join lateral (values
  (1, p.title, replace(x.b2, E'- **The issue tracker** for engineering and product work.\n', E'- **A shared spreadsheet** for engineering and product work.\n'), 'maya', '40 days 2 hours', ''),
  (2, p.title, x.b2, 'jonah', '27 days 3 hours', ''),
  (3, p.title, p.body, 'maya', '4 days 1 hour', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Welcome to the team';

-- Your first week
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (
  select replace(p.body, ' Jonah Reyes started on Aug 17 and has already volunteered for the next two engineering hires.', '') as b2
) x
cross join lateral (values
  (1, p.title, regexp_replace(x.b2, E'\n## The ride-along.*?(?=\n## Things)', ''), 'maya', '39 days 3 hours', ''),
  (2, p.title, x.b2, 'jonah', '22 days 6 hours', ''),
  (3, p.title, p.body, 'maya', '2 days 20 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Your first week';

-- Accounts and tools checklist
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (values
  (1, p.title, replace(replace(p.body, E'- [ ] Run through [Local development setup](#)\n', ''), '| Engineering | 14" laptop, 36 GB |', '| Engineering | 14" laptop, 32 GB |'), 'jonah', '38 days 7 hours', ''),
  (2, p.title, p.body, 'theo', '20 days 3 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Accounts and tools checklist';

-- Time off and holidays
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (values
  (1, p.title, replace(regexp_replace(p.body, E'\n### On-call and time off.*$', ''), '**16 weeks fully paid**', '**12 weeks fully paid**'), 'maya', '37 days 2 hours', ''),
  (2, p.title, p.body, 'priya', '9 days 6 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Time off and holidays';

-- Expenses
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (
  select replace(p.body, E'```text\nGood reason: "Ride-along with Harbor Electric, Tacoma, Sep 18"\nBad reason:  "travel"\n```\n\n', '') as b2
) x
cross join lateral (values
  (1, p.title, replace(replace(x.b2, '| Internet | $80 a month |', '| Internet | $60 a month |'), 'Snap the receipt in the **expense app** within 7 days', 'Snap the receipt in the **expense app** within 30 days'), 'maya', '35 days 9 hours', ''),
  (2, p.title, x.b2, 'maya', '16 days 2 hours', ''),
  (3, p.title, p.body, 'jonah', '1 day 18 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Expenses';

-- Remote work
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (values
  (1, p.title, replace(replace(p.body, 'The fall 2026 offsite is in **Denver, Oct 20-22**.', 'The fall 2026 offsite location is still being decided.'), E'3. If a thread goes past 20 replies, summarize it on a page here and link it.\n', ''), 'maya', '34 days 4 hours', ''),
  (2, p.title, p.body, 'theo', '12 days 7 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Remote work';

-- Security basics
insert into page_versions (page_id, version, title, body, author_id, created_at, note)
select p.id, v.n, v.t, v.b, u.id, now() - v.ago::interval, v.note
from pages p
cross join lateral (
  select replace(p.body, 'about 1.3 million homeowners', 'about 1.1 million homeowners') as b2
) x
cross join lateral (values
  (1, p.title, replace(regexp_replace(x.b2, E'\n## Devices.*?(?=\n## If something)', ''), 'Never paste customer data into chat, email or an AI tool.', 'Never paste customer data into chat or email.'), 'theo', '30 days 3 hours', ''),
  (2, p.title, x.b2, 'maya', '18 days 7 hours', ''),
  (3, p.title, p.body, 'theo', '6 days 9 hours', '')
) v(n, t, b, who, ago, note)
join users u on u.email = v.who || '@lorebarn.dev'
where p.title = 'Security basics';

------------------------------------------------------------------------------
-- each page mirrors its latest version
------------------------------------------------------------------------------

update pages p
set
  title = latest.title,
  body = latest.body,
  version = latest.version,
  updated_by = latest.author_id,
  updated_at = latest.created_at,
  created_at = firsts.created_at
from
  (select distinct on (page_id) * from page_versions order by page_id, version desc) latest,
  (select page_id, min(created_at) as created_at from page_versions group by page_id) firsts
where latest.page_id = p.id and firsts.page_id = p.id;

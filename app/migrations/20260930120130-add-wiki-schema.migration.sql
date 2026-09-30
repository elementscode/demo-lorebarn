-- add wiki schema

create or replace function touchUpdatedAt()
returns trigger
language plpgsql
as $$
begin
  new.updatedAt = now();
  return new;
end;
$$;

create type userRole as enum ('member', 'admin');

create table users (
  id uuid primary key default uuidGenerateV7(),
  createdAt timestamptz not null default now(),
  updatedAt timestamptz not null default now(),
  email text not null unique,
  name text not null,
  passwordHash text not null,
  role userRole not null default 'member'
);

create trigger usersTouchUpdatedAt
  before update on users
  for each row execute function touchUpdatedAt();

create table invites (
  id uuid primary key default uuidGenerateV7(),
  createdAt timestamptz not null default now(),
  email text not null,
  role userRole not null default 'member',
  token text not null unique default encode(genRandomBytes(24), 'hex'),
  invitedBy uuid not null references users (id) on delete cascade,
  acceptedAt timestamptz
);

create unique index invitesPendingEmailIdx on invites (email) where acceptedAt is null;

create table spaces (
  id uuid primary key default uuidGenerateV7(),
  createdAt timestamptz not null default now(),
  slug text not null unique,
  name text not null,
  description text not null default '',
  position int not null default 0
);

create table pages (
  id uuid primary key default uuidGenerateV7(),
  createdAt timestamptz not null default now(),
  updatedAt timestamptz not null default now(),
  spaceId uuid not null references spaces (id) on delete cascade,
  parentId uuid references pages (id) on delete restrict,
  position double precision not null default 0,
  title text not null,
  body text not null default '',
  version int not null default 1,
  updatedBy uuid references users (id) on delete set null,
  searchVector tsvector generated always as (
    setweight(to_tsvector('english', title), 'A') ||
    setweight(to_tsvector('english', body), 'B')
  ) stored
);

create index pagesSpaceIdIdx on pages (spaceId);
create index pagesParentIdIdx on pages (parentId);
create index pagesUpdatedAtIdx on pages (updatedAt desc);
create index pagesSearchIdx on pages using gin (searchVector);

create table pageVersions (
  id uuid primary key default uuidGenerateV7(),
  createdAt timestamptz not null default now(),
  pageId uuid not null references pages (id) on delete cascade,
  version int not null,
  title text not null,
  body text not null,
  authorId uuid references users (id) on delete set null,
  note text not null default '',
  unique (pageId, version)
);

create table pagePresence (
  listenerId text primary key,
  createdAt timestamptz not null default now(),
  pageId uuid not null,
  userId uuid not null,
  userName text not null,
  editing boolean not null default false,
  host text not null
);

create index pagePresencePageIdIdx on pagePresence (pageId);
create index pagePresenceHostIdx on pagePresence (host);

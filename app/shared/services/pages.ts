import { LiveTable, LiveView, ValidationError, ForbiddenError, session, sql, tx } from "@elements/app";

export interface Page {
  id: string;
  spaceId: string;
  spaceSlug: string;
  parentId: string | null;
  position: number;
  title: string;
  body: string;
  version: number;
  createdAt: Date;
  updatedAt: Date;
  updatedBy: string | null;
  updatedByName: string | null;
}

export interface Space {
  id: string;
  slug: string;
  name: string;
  description: string;
}

export interface TreeNode {
  id: string;
  page: Page;
  depth: number;
  children: TreeNode[];
}

const MAX_TITLE = 200;

function selectPage(id: string): Page {
  return sql<Page>(`
    select p.id, p.spaceId, s.slug as spaceSlug, p.parentId, p.position, p.title,
           p.body, p.version, p.createdAt, p.updatedAt, p.updatedBy,
           u.name as updatedByName
    from pages p
    join spaces s on s.id = p.spaceId
    left join users u on u.id = p.updatedBy
    where p.id = ${id}
  `).firstOrThrow("page not found");
}

function cleanTitle(title: string | undefined): string {
  let clean = (title ?? "").trim();

  if (!clean) {
    throw new ValidationError("A page needs a title.");
  }

  if (clean.length > MAX_TITLE) {
    throw new ValidationError(`Keep the title under ${MAX_TITLE} characters.`);
  }

  return clean;
}

/**
 * Walks up from `parentId` so a move can never put a page under itself or one
 * of its own descendants.
 */
function assertNotDescendant(pageId: string, parentId: string | null) {
  if (!parentId) {
    return;
  }

  let cycle = sql(`
    with recursive up as (
      select id, parentId from pages where id = ${parentId}
      union all
      select p.id, p.parentId from pages p join up on p.id = up.parentId
    )
    select 1 from up where id = ${pageId}
  `);

  if (!cycle.empty()) {
    throw new ValidationError("A page can't be moved under itself.");
  }
}

function assertParentInSpace(parentId: string | null | undefined, spaceId: string) {
  if (!parentId) {
    return;
  }

  let parent = sql(`select 1 from pages where id = ${parentId} and spaceId = ${spaceId}`);

  if (parent.empty()) {
    throw new ValidationError("That parent page is in another space.");
  }
}

export let pages: LiveTable<Page> = new LiveTable<Page>({
  select: (partition, w) => {
    let inSpace = partition.spaceId ? sql.raw(`p.spaceId = ${partition.spaceId}`) : sql.raw(`true`);

    return sql<Page>(`
      select p.id, p.spaceId, s.slug as spaceSlug, p.parentId, p.position, p.title,
             p.body, p.version, p.createdAt, p.updatedAt, p.updatedBy,
             u.name as updatedByName
      from pages p
      join spaces s on s.id = p.spaceId
      left join users u on u.id = p.updatedBy
      where ${inSpace} and ${w.keyset("p")}
      order by ${w.order("p")} ${w.page()}
    `);
  },

  insert: (item) => {
    let userId = session.getOrThrow("userId");
    let title = cleanTitle(item.title);
    let spaceId = item.spaceId!;

    assertParentInSpace(item.parentId, spaceId);

    return tx(() => {
      let { position } = sql<{ position: number }>(`
        select coalesce(max(position), 0) + 1 as position
        from pages
        where spaceId = ${spaceId} and parentId is not distinct from ${item.parentId ?? null}
      `).firstOrThrow();

      sql(`
        insert into pages (id, spaceId, parentId, position, title, body, version, updatedBy)
             values (${item.id}, ${spaceId}, ${item.parentId ?? null}, ${position}, ${title}, ${item.body ?? ""}, 1, ${userId})
      `);

      sql(`
        insert into pageVersions (pageId, version, title, body, authorId)
             values (${item.id}, 1, ${title}, ${item.body ?? ""}, ${userId})
      `);

      return selectPage(item.id!);
    });
  },

  /**
   * One handler covers both kinds of write. A change to the title or body is
   * an edit: it has to be made against the latest version, bumps the version
   * and keeps a snapshot. A change to parent or position is a move in the
   * tree and leaves the history alone.
   */
  update: (item) => {
    let userId = session.getOrThrow("userId");

    return tx(() => {
      let current = sql<Page>(`
        select p.id, p.spaceId, p.parentId, p.position, p.title, p.body, p.version,
               u.name as updatedByName
        from pages p
        left join users u on u.id = p.updatedBy
        where p.id = ${item.id}
        for update of p
      `).firstOrThrow("page not found");

      if (item.spaceId !== current.spaceId) {
        throw new ValidationError("Pages can't move between spaces.");
      }

      let title = cleanTitle(item.title);
      let edited = title !== current.title || item.body !== current.body;

      if (edited && item.version !== current.version) {
        throw new ValidationError(
          `${current.updatedByName ?? "Someone"} saved version ${current.version} while you were editing.`,
        );
      }

      let moved = item.parentId !== current.parentId || item.position !== current.position;

      if (moved) {
        assertParentInSpace(item.parentId, current.spaceId);
        assertNotDescendant(current.id, item.parentId);

        sql(`update pages set parentId = ${item.parentId}, position = ${item.position} where id = ${item.id}`);
      }

      if (edited) {
        let version = current.version + 1;

        sql(`
          update pages
             set title = ${title}, body = ${item.body}, version = ${version},
                 updatedAt = now(), updatedBy = ${userId}
           where id = ${item.id}
        `);

        sql(`
          insert into pageVersions (pageId, version, title, body, authorId)
               values (${item.id}, ${version}, ${title}, ${item.body}, ${userId})
        `);
      }

      return selectPage(item.id);
    });
  },

  delete: (item) => {
    session.getOrThrow("userId");

    let children = sql(`select 1 from pages where parentId = ${item.id}`);

    if (!children.empty()) {
      throw new ForbiddenError("Move or delete this page's subpages first.");
    }

    sql(`delete from pages where id = ${item.id}`);
  },
});

export function listSpaces(): Space[] {
  return sql<Space>(`select id, slug, name, description from spaces order by position, name`).all();
}

export function findSpace(slug: string): Space | undefined {
  return sql<Space>(`select id, slug, name, description from spaces where slug = ${slug}`).first();
}

export function bySiblingOrder(a: Page, b: Page): number {
  return a.position - b.position || a.title.localeCompare(b.title);
}

/**
 * Builds the nested tree from a space's flat rows. A row whose parent is
 * missing (deleted on another tab a moment ago) is left out rather than shown
 * at the root.
 */
export function buildTree(rows: Iterable<Page>): TreeNode[] {
  let byParent = new Map<string | null, Page[]>();

  for (let page of rows) {
    let list = byParent.get(page.parentId) ?? [];
    list.push(page);
    byParent.set(page.parentId, list);
  }

  function nodes(parentId: string | null, depth: number): TreeNode[] {
    let list = (byParent.get(parentId) ?? []).sort(bySiblingOrder);

    return list.map((page) => ({ id: page.id, page, depth, children: nodes(page.id, depth + 1) }));
  }

  return nodes(null, 0);
}

export function flattenTree(tree: TreeNode[]): TreeNode[] {
  let out: TreeNode[] = [];

  for (let node of tree) {
    out.push(node);
    out.push(...flattenTree(node.children));
  }

  return out;
}

export function ancestors(rows: LiveView<Page> | Page[], page: Page): Page[] {
  let byId = new Map<string, Page>();

  for (let row of rows) {
    byId.set(row.id, row);
  }

  let trail: Page[] = [];
  let parentId = page.parentId;

  while (parentId && byId.has(parentId) && trail.length < 20) {
    let parent = byId.get(parentId)!;
    trail.unshift(parent);
    parentId = parent.parentId;
  }

  return trail;
}

export function pageUrl(page: { id: string; spaceSlug: string }): string {
  return `/s/${page.spaceSlug}/${page.id}`;
}

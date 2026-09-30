import { session, sql } from "@elements/app";

/** Rows the tests build on. The test database has no seed, so each test makes its own. */
export function makeUser(name: string, role: "admin" | "member" = "member"): string {
  let email = `${name.toLowerCase().replace(/\s+/g, ".")}@test.dev`;

  return sql<{ id: string }>(`
    insert into users (email, name, passwordHash, role)
         values (${email}, ${name}, crypt('password1', genSalt('bf', 4)), ${role})
    returning id
  `).firstOrThrow().id;
}

export function makeSpace(slug: string): string {
  return sql<{ id: string }>(`
    insert into spaces (slug, name) values (${slug}, ${slug}) returning id
  `).firstOrThrow().id;
}

export function loginAs(userId: string, name: string, role: "admin" | "member" = "member") {
  session.login({ userId, userName: name, role });
}

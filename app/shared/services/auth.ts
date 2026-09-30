import { sql, session, AuthError, ForbiddenError, redirect } from "@elements/app";

interface Account {
  id: string;
  name: string;
  role: "admin" | "member";
}

export const MIN_PASSWORD = 8;

export function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

export function isEmail(email: string): boolean {
  return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
}

/** @rpc */
export function signin(email: string, password: string) {
  let address = normalizeEmail(email);

  if (!address || !password) {
    throw new AuthError("Enter your email and password.");
  }

  let user = sql<Account>(
    `select id, name, role from users
     where email = ${address}
       and passwordHash = crypt(${password}, passwordHash)`,
  ).first();

  if (!user) {
    throw new AuthError("That email and password don't match an account.");
  }

  session.login({ userId: user.id, userName: user.name, role: user.role });
}

/** @rpc */
export function signout() {
  session.logout();
  redirect("/signin");
}

export function isUserAdmin(userId: string): boolean {
  return !sql(`select 1 from users where id = ${userId} and role = 'admin'`).empty();
}

export function requireAdmin(): string {
  let userId = session.getOrThrow("userId");

  if (!isUserAdmin(userId)) {
    throw new ForbiddenError("Only admins can do that.");
  }

  return userId;
}

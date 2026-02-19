import { type Page } from "@playwright/test";

export const TEST_USERS = {
  trainer: {
    email: "trainer@test.com",
    password: "TestPass123!",
  },
  admin: {
    email: "admin@test.com",
    password: "AdminPass123!",
  },
  ambassador: {
    email: "ambassador@test.com",
    password: "AmbassadorPass123!",
  },
} as const;

export async function loginAs(
  page: Page,
  role: keyof typeof TEST_USERS,
): Promise<void> {
  const { email, password } = TEST_USERS[role];
  await page.goto("/login");
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Password").fill(password);
  await page.getByRole("button", { name: /sign in/i }).click();

  // Wait for redirect after successful login
  const expectedPath =
    role === "admin"
      ? "/admin/dashboard"
      : role === "ambassador"
        ? "/ambassador/dashboard"
        : "/dashboard";

  await page.waitForURL(`**${expectedPath}`, { timeout: 10000 });
}

export async function logout(page: Page): Promise<void> {
  // Open user menu and click sign out
  await page.getByRole("button", { name: /user menu/i }).click();
  await page.getByRole("menuitem", { name: /sign out/i }).click();
  await page.waitForURL("**/login", { timeout: 10000 });
}

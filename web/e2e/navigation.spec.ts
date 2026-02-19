import { test, expect } from "@playwright/test";

test.describe("Navigation Guards", () => {
  test("should redirect /dashboard to /login when unauthenticated", async ({
    page,
  }) => {
    await page.goto("/dashboard");
    await page.waitForURL("**/login", { timeout: 10000 });
  });

  test("should redirect /admin/dashboard to /login when unauthenticated", async ({
    page,
  }) => {
    await page.goto("/admin/dashboard");
    await page.waitForURL("**/login", { timeout: 10000 });
  });

  test("should redirect /ambassador/dashboard to /login when unauthenticated", async ({
    page,
  }) => {
    await page.goto("/ambassador/dashboard");
    await page.waitForURL("**/login", { timeout: 10000 });
  });

  test("should redirect / to /login when unauthenticated", async ({
    page,
  }) => {
    await page.goto("/");
    await page.waitForURL("**/login", { timeout: 10000 });
  });
});

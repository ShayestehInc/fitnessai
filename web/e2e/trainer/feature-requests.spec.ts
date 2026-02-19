import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Feature Requests", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "trainer");
    await page.getByRole("link", { name: /feature requests/i }).click();
    await page.waitForURL("**/feature-requests");
  });

  test("should display feature requests page", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /feature requests/i }),
    ).toBeVisible();
  });

  test("should have submit request button", async ({ page }) => {
    await expect(
      page.getByRole("button", { name: /submit|new|request/i }),
    ).toBeVisible();
  });

  test("should open submit dialog", async ({ page }) => {
    await page.getByRole("button", { name: /submit|new|request/i }).click();
    await expect(page.getByRole("dialog")).toBeVisible();
  });
});

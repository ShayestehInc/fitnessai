import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Admin Settings", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "admin");
    await page.getByRole("link", { name: /settings/i }).click();
    await page.waitForURL("**/admin/settings");
  });

  test("should display admin settings page", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /admin settings/i }),
    ).toBeVisible();
  });

  test("should show platform configuration section", async ({ page }) => {
    // Platform Configuration is a CardTitle (h3)
    await expect(
      page.getByRole("heading", { name: /platform configuration/i }),
    ).toBeVisible();
  });

  test("should show security section", async ({ page }) => {
    // There are two Security headings (admin card + SecuritySection), use first
    await expect(
      page.getByRole("heading", { name: /^security$/i }).first(),
    ).toBeVisible();
  });

  test("should show profile section", async ({ page }) => {
    // Profile section heading
    await expect(
      page.getByRole("heading", { name: /^profile$/i }),
    ).toBeVisible();
  });

  test("should show appearance section", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /appearance/i }),
    ).toBeVisible();
  });
});

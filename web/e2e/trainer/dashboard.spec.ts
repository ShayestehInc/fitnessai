import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Trainer Dashboard", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "trainer");
  });

  test("should display dashboard with stats", async ({ page }) => {
    await expect(page.getByRole("heading", { name: /dashboard/i })).toBeVisible();
    // Should see stat cards
    await expect(page.getByText(/total trainees/i)).toBeVisible();
    await expect(page.getByText(/active today/i)).toBeVisible();
  });

  test("should display sidebar navigation", async ({ page }) => {
    await expect(page.getByRole("link", { name: /dashboard/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /trainees/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /programs/i })).toBeVisible();
  });

  test("should navigate to trainees page", async ({ page }) => {
    await page.getByRole("link", { name: /trainees/i }).click();
    await page.waitForURL("**/trainees");
    await expect(page.getByRole("heading", { name: /trainees/i })).toBeVisible();
  });

  test("should navigate to settings page", async ({ page }) => {
    await page.getByRole("link", { name: /settings/i }).click();
    await page.waitForURL("**/settings");
    await expect(page.getByRole("heading", { name: /settings/i })).toBeVisible();
  });
});

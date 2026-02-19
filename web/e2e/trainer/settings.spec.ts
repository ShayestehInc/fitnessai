import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Trainer Settings", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "trainer");
    await page.getByRole("link", { name: /settings/i }).click();
    await page.waitForURL("**/settings");
  });

  test("should display settings page with all sections", async ({ page }) => {
    await expect(page.getByRole("heading", { name: /settings/i })).toBeVisible();
    // Profile section
    await expect(page.getByText(/profile/i)).toBeVisible();
    // Branding section
    await expect(page.getByText(/branding/i)).toBeVisible();
    // Leaderboard section
    await expect(page.getByText(/leaderboard/i)).toBeVisible();
    // Appearance section
    await expect(page.getByText(/appearance/i)).toBeVisible();
    // Security section
    await expect(page.getByText(/security/i)).toBeVisible();
  });

  test("branding section should have color pickers", async ({ page }) => {
    await expect(page.getByText(/primary color/i)).toBeVisible();
    await expect(page.getByText(/secondary color/i)).toBeVisible();
  });

  test("branding section should have app name field", async ({ page }) => {
    await expect(page.getByLabel(/app name/i)).toBeVisible();
  });

  test("appearance section should have theme options", async ({ page }) => {
    await expect(page.getByText(/light/i)).toBeVisible();
    await expect(page.getByText(/dark/i)).toBeVisible();
    await expect(page.getByText(/system/i)).toBeVisible();
  });
});

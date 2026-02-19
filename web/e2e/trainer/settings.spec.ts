import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Trainer Settings", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "trainer");
    await page.getByRole("link", { name: /settings/i }).click();
    await page.waitForURL("**/settings");
  });

  test("should display settings page with all sections", async ({ page }) => {
    // Page header (h1)
    await expect(
      page.getByRole("heading", { name: /^settings$/i }),
    ).toBeVisible();
    // Section headings (h3 via CardTitle)
    await expect(
      page.getByRole("heading", { name: /^profile$/i }),
    ).toBeVisible();
    await expect(
      page.getByRole("heading", { name: /branding/i }),
    ).toBeVisible();
    await expect(
      page.getByRole("heading", { name: /leaderboard/i }),
    ).toBeVisible();
    await expect(
      page.getByRole("heading", { name: /appearance/i }),
    ).toBeVisible();
  });

  test("branding section should have color pickers", async ({ page }) => {
    await expect(page.getByText(/primary color/i)).toBeVisible();
    await expect(page.getByText(/secondary color/i)).toBeVisible();
  });

  test("branding section should have app name field", async ({ page }) => {
    await expect(page.getByLabel(/app name/i)).toBeVisible();
  });

  test("appearance section should have theme options", async ({ page }) => {
    await expect(page.getByText(/light/i).first()).toBeVisible();
    await expect(page.getByText(/dark/i).first()).toBeVisible();
    await expect(page.getByText(/system/i).first()).toBeVisible();
  });
});

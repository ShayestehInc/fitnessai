import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Ambassador Settings", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "ambassador");
    await page.getByRole("link", { name: /settings/i }).click();
    await page.waitForURL("**/ambassador/settings");
  });

  test("should display settings page", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /settings/i }),
    ).toBeVisible();
  });

  test("should show profile section", async ({ page }) => {
    await expect(page.getByText(/profile/i)).toBeVisible();
  });

  test("should show appearance section", async ({ page }) => {
    await expect(page.getByText(/appearance/i)).toBeVisible();
  });

  test("should show security section", async ({ page }) => {
    await expect(page.getByText(/security/i)).toBeVisible();
  });
});

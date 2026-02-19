import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Admin Ambassador Management", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "admin");
    await page.getByRole("link", { name: /ambassadors/i }).click();
    await page.waitForURL("**/admin/ambassadors");
  });

  test("should display ambassadors page", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /ambassadors/i }),
    ).toBeVisible();
  });

  test("should have add ambassador button", async ({ page }) => {
    // There may be multiple "Add Ambassador" buttons (toolbar + empty state)
    await expect(
      page.getByRole("button", { name: /add ambassador/i }).first(),
    ).toBeVisible();
  });

  test("should have search input", async ({ page }) => {
    await expect(
      page.getByPlaceholder(/search ambassadors/i),
    ).toBeVisible();
  });

  test("should open create ambassador dialog", async ({ page }) => {
    await page
      .getByRole("button", { name: /add ambassador/i })
      .first()
      .click();
    await expect(page.getByRole("dialog")).toBeVisible();
    await expect(
      page.getByRole("heading", { name: /add ambassador/i }),
    ).toBeVisible();
  });

  test("create dialog should have email and commission fields", async ({
    page,
  }) => {
    await page
      .getByRole("button", { name: /add ambassador/i })
      .first()
      .click();
    await expect(page.getByLabel(/email/i)).toBeVisible();
    await expect(page.getByLabel(/commission/i)).toBeVisible();
  });

  test("should validate email in create dialog", async ({ page }) => {
    await page
      .getByRole("button", { name: /add ambassador/i })
      .first()
      .click();
    await page.getByRole("button", { name: /^create$/i }).click();
    await expect(page.getByText(/valid email/i)).toBeVisible();
  });
});

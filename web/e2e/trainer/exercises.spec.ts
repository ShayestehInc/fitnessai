import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Exercise Bank", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "trainer");
    await page.getByRole("link", { name: /exercises/i }).click();
    await page.waitForURL("**/exercises");
  });

  test("should display exercises page", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /exercise bank/i }),
    ).toBeVisible();
  });

  test("should have search input", async ({ page }) => {
    await expect(page.getByPlaceholder(/search exercises/i)).toBeVisible();
  });

  test("should have muscle group filter chips", async ({ page }) => {
    await expect(page.getByRole("button", { name: /all/i })).toBeVisible();
  });

  test("should have create exercise button", async ({ page }) => {
    await expect(
      page.getByRole("button", { name: /create exercise/i }),
    ).toBeVisible();
  });

  test("should open create exercise dialog", async ({ page }) => {
    await page.getByRole("button", { name: /create exercise/i }).click();
    await expect(page.getByRole("dialog")).toBeVisible();
    await expect(
      page.getByRole("heading", { name: /create exercise/i }),
    ).toBeVisible();
  });

  test("create dialog should validate required fields", async ({ page }) => {
    await page.getByRole("button", { name: /create exercise/i }).click();
    await page.getByRole("button", { name: /^create$/i }).click();
    // Should show validation errors
    await expect(page.getByText(/name is required/i)).toBeVisible();
    await expect(page.getByText(/muscle group is required/i)).toBeVisible();
  });
});

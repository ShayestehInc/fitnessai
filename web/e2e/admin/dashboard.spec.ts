import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Admin Dashboard", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "admin");
  });

  test("should display admin dashboard", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /dashboard/i }),
    ).toBeVisible();
  });

  test("should show admin navigation", async ({ page }) => {
    await expect(page.getByRole("link", { name: /trainers/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /users/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /tiers/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /ambassadors/i })).toBeVisible();
  });

  test("should navigate to ambassadors page", async ({ page }) => {
    await page.getByRole("link", { name: /ambassadors/i }).click();
    await page.waitForURL("**/admin/ambassadors");
    await expect(
      page.getByRole("heading", { name: /ambassadors/i }),
    ).toBeVisible();
  });

  test("should navigate to upcoming payments", async ({ page }) => {
    await page.getByRole("link", { name: /upcoming/i }).click();
    await page.waitForURL("**/admin/upcoming-payments");
    await expect(
      page.getByRole("heading", { name: /upcoming payments/i }),
    ).toBeVisible();
  });

  test("should navigate to past due", async ({ page }) => {
    await page.getByRole("link", { name: /past due/i }).click();
    await page.waitForURL("**/admin/past-due");
    await expect(
      page.getByRole("heading", { name: /past due/i }),
    ).toBeVisible();
  });
});

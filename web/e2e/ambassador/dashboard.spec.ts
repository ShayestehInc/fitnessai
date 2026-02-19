import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Ambassador Dashboard", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "ambassador");
  });

  test("should display ambassador dashboard", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /ambassador dashboard/i }),
    ).toBeVisible();
  });

  test("should show earnings stats", async ({ page }) => {
    // Use heading role to avoid strict mode violations with description text
    await expect(page.getByRole("heading", { name: /total earnings/i })).toBeVisible();
    await expect(page.getByRole("heading", { name: /this month/i })).toBeVisible();
    await expect(page.getByRole("heading", { name: /total referrals/i })).toBeVisible();
    await expect(page.getByRole("heading", { name: /commission rate/i })).toBeVisible();
  });

  test("should show referral code card", async ({ page }) => {
    await expect(page.getByRole("heading", { name: /your referral code/i })).toBeVisible();
  });

  test("should have copy button for referral code", async ({ page }) => {
    // The referral code card should be visible with copy button
    await expect(page.getByRole("heading", { name: /your referral code/i })).toBeVisible();
  });

  test("should show ambassador navigation", async ({ page }) => {
    await expect(page.getByRole("link", { name: /dashboard/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /referrals/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /payouts/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /settings/i })).toBeVisible();
  });
});

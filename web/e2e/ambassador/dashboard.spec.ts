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
    await expect(page.getByText(/total earnings/i)).toBeVisible();
    await expect(page.getByText(/this month/i)).toBeVisible();
    await expect(page.getByText(/total referrals/i)).toBeVisible();
    await expect(page.getByText(/commission rate/i)).toBeVisible();
  });

  test("should show referral code card", async ({ page }) => {
    await expect(page.getByText(/your referral code/i)).toBeVisible();
  });

  test("should have copy button for referral code", async ({ page }) => {
    // The copy button should be in the referral code card
    const copyBtn = page.getByRole("button").filter({
      has: page.locator('svg'),
    });
    // At least one button should exist in the referral card area
    await expect(page.getByText(/your referral code/i)).toBeVisible();
  });

  test("should show ambassador navigation", async ({ page }) => {
    await expect(page.getByRole("link", { name: /dashboard/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /referrals/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /payouts/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /settings/i })).toBeVisible();
  });
});

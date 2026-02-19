import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Ambassador Referrals", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "ambassador");
    await page.getByRole("link", { name: /referrals/i }).click();
    await page.waitForURL("**/ambassador/referrals");
  });

  test("should display referrals page", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /referrals/i }),
    ).toBeVisible();
  });

  test("should have search input", async ({ page }) => {
    await expect(
      page.getByPlaceholder(/search referrals/i),
    ).toBeVisible();
  });

  test("should show empty state or referral list", async ({ page }) => {
    // Either shows empty state or list items — use .or() for retrying assertion
    await expect(
      page.getByText(/no referrals yet/i)
        .or(page.locator(".rounded-lg.border").filter({
          has: page.locator("text=/active|inactive/i"),
        }).first()),
    ).toBeVisible();
  });
});

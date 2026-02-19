import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Ambassador Payouts", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "ambassador");
    await page.getByRole("link", { name: /payouts/i }).click();
    await page.waitForURL("**/ambassador/payouts");
  });

  test("should display payouts page", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /payouts/i }).first(),
    ).toBeVisible();
  });

  test("should show Stripe Connect setup section", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /payout account/i }),
    ).toBeVisible();
  });

  test("should show payout history section", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /payout history/i }),
    ).toBeVisible();
  });

  test("should show connect button or connected status", async ({ page }) => {
    // Check for either the connect button or connected status text
    await expect(
      page.getByRole("button", { name: /connect stripe account|complete setup/i })
        .or(page.getByText(/stripe connected/i)),
    ).toBeVisible();
  });
});

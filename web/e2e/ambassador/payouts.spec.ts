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
      page.getByRole("heading", { name: /payouts/i }),
    ).toBeVisible();
  });

  test("should show Stripe Connect setup section", async ({ page }) => {
    await expect(page.getByText(/payout account/i)).toBeVisible();
  });

  test("should show payout history section", async ({ page }) => {
    await expect(page.getByText(/payout history/i)).toBeVisible();
  });

  test("should show connect button or connected status", async ({ page }) => {
    const connectBtn = page.getByRole("button", {
      name: /connect stripe|complete setup/i,
    });
    const connectedText = page.getByText(/stripe connected/i);
    const hasConnect = await connectBtn.isVisible().catch(() => false);
    const hasConnected = await connectedText.isVisible().catch(() => false);
    expect(hasConnect || hasConnected).toBeTruthy();
  });
});

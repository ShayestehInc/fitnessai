import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Subscription Management", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "trainer");
    await page.getByRole("link", { name: /subscription/i }).click();
    await page.waitForURL("**/subscription");
  });

  test("should display subscription page", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /subscription/i }),
    ).toBeVisible();
  });

  test("should show Stripe Connect status", async ({ page }) => {
    // Should show either connect button or connected status
    const connectBtn = page.getByRole("button", { name: /connect|set up/i });
    const connectedText = page.getByText(/connected|active/i);
    const isConnectVisible = await connectBtn.isVisible().catch(() => false);
    const isConnectedVisible = await connectedText.isVisible().catch(() => false);
    expect(isConnectVisible || isConnectedVisible).toBeTruthy();
  });
});

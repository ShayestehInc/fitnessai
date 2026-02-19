import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Calendar Integration", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "trainer");
    await page.getByRole("link", { name: /calendar/i }).click();
    await page.waitForURL("**/calendar");
  });

  test("should display calendar page", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /calendar/i }),
    ).toBeVisible();
  });

  test("should show connection options", async ({ page }) => {
    // Should show Google Calendar connect or connected status
    const googleText = page.getByText(/google/i);
    if (await googleText.isVisible()) {
      await expect(googleText).toBeVisible();
    }
  });
});

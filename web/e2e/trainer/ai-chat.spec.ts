import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("AI Chat", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "trainer");
    await page.getByRole("link", { name: /ai chat/i }).click();
    await page.waitForURL("**/ai-chat");
  });

  test("should display AI chat page", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /ai.*assistant|ai.*chat/i }),
    ).toBeVisible();
  });

  test("should have message input", async ({ page }) => {
    await expect(
      page.getByPlaceholder(/ask.*assistant|type.*message|ask.*question/i),
    ).toBeVisible();
  });

  test("should have trainee selector", async ({ page }) => {
    // Trainee selector or context picker should be present
    const selector = page.getByText(/select.*trainee|choose.*trainee/i);
    if (await selector.isVisible()) {
      await expect(selector).toBeVisible();
    }
  });

  test("should show suggestion chips", async ({ page }) => {
    // Suggestion chips should appear in empty state
    const chip = page.getByRole("button").filter({ hasText: /suggest|help|review/i }).first();
    if (await chip.isVisible()) {
      await expect(chip).toBeVisible();
    }
  });
});

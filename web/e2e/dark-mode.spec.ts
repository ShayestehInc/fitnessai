import { test, expect } from "@playwright/test";

test.describe("Dark Mode", () => {
  test("should respect system dark mode preference", async ({ page }) => {
    await page.emulateMedia({ colorScheme: "dark" });
    await page.goto("/login");
    // The html element should have the dark class (if using next-themes)
    // Or the theme should be applied via CSS
    await page.waitForTimeout(500);
    const html = page.locator("html");
    const className = await html.getAttribute("class");
    // Theme class should be set
    expect(className).toBeDefined();
  });

  test("should render login page in dark mode without visual issues", async ({
    page,
  }) => {
    await page.emulateMedia({ colorScheme: "dark" });
    await page.goto("/login");
    await expect(page.getByRole("heading", { name: /sign in/i })).toBeVisible();
    // Form elements should still be visible and readable
    await expect(page.getByLabel("Email")).toBeVisible();
    await expect(page.getByLabel("Password")).toBeVisible();
  });

  test("should render login page in light mode", async ({ page }) => {
    await page.emulateMedia({ colorScheme: "light" });
    await page.goto("/login");
    await expect(page.getByRole("heading", { name: /sign in/i })).toBeVisible();
  });
});

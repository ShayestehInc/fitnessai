import { test, expect } from "@playwright/test";

test.describe("Authentication", () => {
  test("should show login page", async ({ page }) => {
    await page.goto("/login");
    await expect(page.getByRole("heading", { name: /sign in/i })).toBeVisible();
    await expect(page.getByLabel("Email")).toBeVisible();
    await expect(page.getByLabel("Password")).toBeVisible();
    await expect(page.getByRole("button", { name: /sign in/i })).toBeVisible();
  });

  test("should show validation errors for empty form", async ({ page }) => {
    await page.goto("/login");
    await page.getByRole("button", { name: /sign in/i }).click();
    // Browser native validation should prevent empty submission
    await expect(page.getByLabel("Email")).toBeFocused();
  });

  test("should show error for invalid credentials", async ({ page }) => {
    await page.goto("/login");
    await page.getByLabel("Email").fill("wrong@example.com");
    await page.getByLabel("Password").fill("wrongpassword");
    await page.getByRole("button", { name: /sign in/i }).click();
    // Should show an error message (from API or toast)
    await expect(
      page.getByText(/invalid|unauthorized|failed/i),
    ).toBeVisible({ timeout: 10000 });
  });

  test("should redirect unauthenticated users to login", async ({ page }) => {
    await page.goto("/dashboard");
    await page.waitForURL("**/login", { timeout: 10000 });
  });

  test("login page should have proper hero section on desktop", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto("/login");
    // The login hero should be visible on desktop
    await expect(page.getByText(/Your Fitness/i)).toBeVisible();
  });

  test("login page hero should be hidden on mobile", async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto("/login");
    // The hero column should be hidden on mobile
    await expect(page.getByTestId?.("login-hero") ?? page.locator(".hidden.lg\\:flex")).toBeHidden();
  });
});

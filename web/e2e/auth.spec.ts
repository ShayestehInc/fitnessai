import { test, expect } from "@playwright/test";

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8500";

test.describe("Authentication", () => {
  test("should show login page", async ({ page }) => {
    await page.goto("/login");
    // The card title "FitnessAI" is rendered as an h3 heading
    await expect(
      page.getByRole("heading", { name: /fitnessai/i }),
    ).toBeVisible();
    await expect(page.getByText(/sign in to your dashboard/i)).toBeVisible();
    await expect(page.getByLabel("Email")).toBeVisible();
    await expect(page.getByLabel("Password")).toBeVisible();
    await expect(
      page.getByRole("button", { name: /sign in/i }),
    ).toBeVisible();
  });

  test("should show validation errors for empty form", async ({ page }) => {
    await page.goto("/login");
    await page.getByRole("button", { name: /sign in/i }).click();
    // Browser native validation should prevent empty submission
    await expect(page.getByLabel("Email")).toBeFocused();
  });

  test("should show error for invalid credentials", async ({ page }) => {
    // Mock the JWT endpoint to return 401
    await page.route(`${API_BASE}/api/auth/jwt/create/`, async (route) => {
      if (route.request().method() !== "POST") {
        await route.fallback();
        return;
      }
      await route.fulfill({
        status: 401,
        contentType: "application/json",
        body: JSON.stringify({
          detail: "No active account found with the given credentials",
        }),
      });
    });

    await page.goto("/login");
    await page.getByLabel("Email").fill("wrong@example.com");
    await page.getByLabel("Password").fill("wrongpassword");
    await page.getByRole("button", { name: /sign in/i }).click();
    // Should show an error message
    await expect(
      page.getByText(/no active account|invalid|unauthorized|failed/i),
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
    // The login hero words are split into separate motion spans
    // and the parent div has aria-hidden="true", so use CSS locators
    await expect(
      page.locator("span", { hasText: "Train" }).first(),
    ).toBeVisible();
    await expect(
      page.locator("span", { hasText: "Smarter." }).first(),
    ).toBeVisible();
  });

  test("login page hero should be hidden on mobile", async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto("/login");
    // On mobile, the hero section is hidden (uses hidden lg:flex)
    // Just verify the login form is visible and hero text is not
    await expect(
      page.getByRole("heading", { name: /fitnessai/i }),
    ).toBeVisible();
    // Hero words are in separate spans - check the first word
    await expect(
      page.locator("span", { hasText: "Train" }).first(),
    ).toBeHidden();
  });
});

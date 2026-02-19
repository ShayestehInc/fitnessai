import { test, expect } from "@playwright/test";

test.describe("Error States", () => {
  test("should show 404 page for unknown routes", async ({ page }) => {
    await page.goto("/this-page-does-not-exist");
    // Should show a not-found page or redirect to login
    const notFoundText = page.getByText(/not found|404|page.*not/i);
    const loginRedirect = page.getByRole("heading", { name: /sign in/i });
    const hasNotFound = await notFoundText.isVisible().catch(() => false);
    const hasLogin = await loginRedirect.isVisible().catch(() => false);
    expect(hasNotFound || hasLogin).toBeTruthy();
  });

  test("should show error state when API fails", async ({ page }) => {
    // Block all API requests to simulate network failure
    await page.route("**/api/**", (route) =>
      route.fulfill({ status: 500, body: '{"detail":"Server Error"}' }),
    );

    await page.goto("/login");
    await page.getByLabel("Email").fill("test@test.com");
    await page.getByLabel("Password").fill("password");
    await page.getByRole("button", { name: /sign in/i }).click();

    // Should show an error message
    await expect(
      page.getByText(/error|failed|server/i),
    ).toBeVisible({ timeout: 10000 });
  });
});

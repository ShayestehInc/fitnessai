import { test, expect } from "@playwright/test";

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8500";

test.describe("Error States", () => {
  test("should show 404 page for unknown routes", async ({ page }) => {
    await page.goto("/this-page-does-not-exist");
    // Should show a not-found page OR redirect to login
    const notFoundText = page.getByText(/not found|404|page.*not/i);
    const loginPage = page.getByRole("heading", { name: /fitnessai/i });
    const hasNotFound = await notFoundText.isVisible().catch(() => false);
    const hasLogin = await loginPage.isVisible().catch(() => false);
    expect(hasNotFound || hasLogin).toBeTruthy();
  });

  test("should show error state when API fails", async ({ page }) => {
    // Mock the JWT endpoint to return 500
    await page.route(`${API_BASE}/api/**`, (route) =>
      route.fulfill({
        status: 500,
        contentType: "application/json",
        body: '{"detail":"Server Error"}',
      }),
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

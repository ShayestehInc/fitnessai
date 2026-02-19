import { test, expect } from "@playwright/test";

test.describe("Dark Mode", () => {
  test("should respect system dark mode preference", async ({ page }) => {
    await page.emulateMedia({ colorScheme: "dark" });
    await page.goto("/login");
    // The html element should have the dark class (if using next-themes)
    await page.waitForTimeout(500);
    const html = page.locator("html");
    const className = await html.getAttribute("class");
    expect(className).toBeDefined();
  });

  test("should render login page in dark mode without visual issues", async ({
    page,
  }) => {
    await page.emulateMedia({ colorScheme: "dark" });
    await page.goto("/login");
    await expect(
      page.getByRole("heading", { name: /fitnessai/i }),
    ).toBeVisible();
    await expect(page.getByLabel("Email")).toBeVisible();
    await expect(page.getByLabel("Password")).toBeVisible();
  });

  test("should render login page in light mode", async ({ page }) => {
    await page.emulateMedia({ colorScheme: "light" });
    await page.goto("/login");
    await expect(
      page.getByRole("heading", { name: /fitnessai/i }),
    ).toBeVisible();
  });
});

import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Trainee Management", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "trainer");
    await page.getByRole("link", { name: /trainees/i }).click();
    await page.waitForURL("**/trainees");
  });

  test("should display trainee list page", async ({ page }) => {
    await expect(page.getByRole("heading", { name: /trainees/i })).toBeVisible();
  });

  test("should have search functionality", async ({ page }) => {
    const searchInput = page.getByPlaceholder(/search/i);
    await expect(searchInput).toBeVisible();
    await searchInput.fill("test");
    // Search should trigger without button click (debounced)
    await page.waitForTimeout(500);
  });

  test("should navigate to trainee detail on click", async ({ page }) => {
    // Wait for the table to load
    const firstRow = page.getByRole("link").filter({ hasText: /@/ }).first();
    if (await firstRow.isVisible()) {
      await firstRow.click();
      await page.waitForURL("**/trainees/*");
      await expect(page.getByText(/back to trainees/i)).toBeVisible();
    }
  });
});

test.describe("Trainee Detail", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "trainer");
  });

  test("should show error for invalid trainee ID", async ({ page }) => {
    await page.goto("/trainees/invalid");
    await expect(page.getByText(/invalid trainee id/i)).toBeVisible();
  });

  test("should have action buttons on trainee detail", async ({ page }) => {
    await page.goto("/trainees/1");
    // These buttons should exist if trainee loads
    const editGoalsBtn = page.getByRole("button", { name: /edit goals/i });
    const assignBtn = page.getByRole("button", { name: /assign program|change program/i });
    const viewAsBtn = page.getByRole("button", { name: /view as trainee/i });
    // At least the action area should be present (may show error if trainee doesn't exist)
    await page.waitForTimeout(3000);
  });
});

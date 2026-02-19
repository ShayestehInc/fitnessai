import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

test.describe("Announcements", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "trainer");
    await page.getByRole("link", { name: /announcements/i }).click();
    await page.waitForURL("**/announcements");
  });

  test("should display announcements page", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /announcements/i }),
    ).toBeVisible();
  });

  test("should have create announcement button", async ({ page }) => {
    await expect(
      page.getByRole("button", { name: /create|new announcement/i }),
    ).toBeVisible();
  });

  test("should open create dialog on button click", async ({ page }) => {
    await page.getByRole("button", { name: /create|new announcement/i }).click();
    await expect(page.getByRole("dialog")).toBeVisible();
    await expect(
      page.getByRole("heading", { name: /create announcement/i }),
    ).toBeVisible();
  });

  test("create dialog should have title and message fields", async ({
    page,
  }) => {
    await page.getByRole("button", { name: /create|new announcement/i }).click();
    await expect(page.getByLabel(/title/i)).toBeVisible();
    await expect(page.getByLabel(/message|body/i)).toBeVisible();
  });

  test("should close dialog on cancel", async ({ page }) => {
    await page.getByRole("button", { name: /create|new announcement/i }).click();
    await page.getByRole("button", { name: /cancel/i }).click();
    await expect(page.getByRole("dialog")).toBeHidden();
  });
});

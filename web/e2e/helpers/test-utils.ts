import { type Page, expect } from "@playwright/test";

/**
 * Wait for the page to be fully loaded (no loading spinners visible).
 */
export async function waitForPageLoad(page: Page): Promise<void> {
  // Wait for any loading spinners to disappear
  await page.waitForLoadState("networkidle");
  const spinner = page.locator('[class*="animate-spin"]');
  if (await spinner.isVisible()) {
    await spinner.waitFor({ state: "hidden", timeout: 10000 });
  }
}

/**
 * Assert a toast notification appears with expected text.
 */
export async function expectToast(
  page: Page,
  text: string | RegExp,
): Promise<void> {
  const toast = page.getByRole("status").or(page.locator("[data-sonner-toast]"));
  await expect(toast.filter({ hasText: text })).toBeVisible({ timeout: 5000 });
}

/**
 * Assert the page title matches.
 */
export async function expectPageTitle(
  page: Page,
  title: string,
): Promise<void> {
  await expect(page.getByRole("heading", { name: title })).toBeVisible();
}

/**
 * Navigate to a page via sidebar link.
 */
export async function navigateVia(
  page: Page,
  linkText: string,
): Promise<void> {
  await page.getByRole("link", { name: linkText }).click();
  await waitForPageLoad(page);
}

/**
 * Check that a dialog opens with the expected title.
 */
export async function expectDialogOpen(
  page: Page,
  title: string,
): Promise<void> {
  await expect(
    page.getByRole("dialog").getByRole("heading", { name: title }),
  ).toBeVisible({ timeout: 5000 });
}

/**
 * Close the currently open dialog.
 */
export async function closeDialog(page: Page): Promise<void> {
  await page.keyboard.press("Escape");
  await expect(page.getByRole("dialog")).toBeHidden({ timeout: 3000 });
}

/**
 * Assert empty state is shown.
 */
export async function expectEmptyState(
  page: Page,
  title: string,
): Promise<void> {
  await expect(page.getByText(title)).toBeVisible();
}

/**
 * Assert error state with retry button.
 */
export async function expectErrorState(page: Page): Promise<void> {
  await expect(
    page.getByRole("button", { name: /retry/i }),
  ).toBeVisible();
}

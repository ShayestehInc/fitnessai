import { test, expect } from "@playwright/test";
import { loginAs } from "../helpers/auth";

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8500";

const MOCK_CONVERSATIONS = [
  {
    id: 1,
    trainer: {
      id: 1,
      first_name: "Test",
      last_name: "Trainer",
      email: "trainer@test.com",
      profile_image: null,
    },
    trainee: {
      id: 10,
      first_name: "Jane",
      last_name: "Doe",
      email: "jane@test.com",
      profile_image: null,
    },
    last_message_at: new Date().toISOString(),
    last_message_preview: "Hey, how is your progress?",
    unread_count: 2,
    is_archived: false,
    created_at: new Date().toISOString(),
  },
  {
    id: 2,
    trainer: {
      id: 1,
      first_name: "Test",
      last_name: "Trainer",
      email: "trainer@test.com",
      profile_image: null,
    },
    trainee: {
      id: 11,
      first_name: "John",
      last_name: "Smith",
      email: "john@test.com",
      profile_image: null,
    },
    last_message_at: new Date(Date.now() - 86400000).toISOString(),
    last_message_preview: "Great workout today!",
    unread_count: 0,
    is_archived: false,
    created_at: new Date(Date.now() - 86400000).toISOString(),
  },
];

const MOCK_MESSAGES = {
  count: 2,
  next: null,
  previous: null,
  results: [
    {
      id: 100,
      conversation_id: 1,
      sender: { id: 1, first_name: "Test", last_name: "Trainer", profile_image: null },
      content: "Hey, how is your progress?",
      is_read: true,
      read_at: new Date().toISOString(),
      created_at: new Date(Date.now() - 3600000).toISOString(),
    },
    {
      id: 101,
      conversation_id: 1,
      sender: { id: 10, first_name: "Jane", last_name: "Doe", profile_image: null },
      content: "Going great, thanks!",
      is_read: false,
      read_at: null,
      created_at: new Date().toISOString(),
    },
  ],
};

test.describe("Trainer Messages", () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, "trainer");
  });

  test("should show Messages link in sidebar navigation", async ({ page }) => {
    await expect(
      page.getByRole("link", { name: /messages/i }),
    ).toBeVisible();
  });

  test("should navigate to messages page", async ({ page }) => {
    await page.getByRole("link", { name: /messages/i }).click();
    await page.waitForURL("**/messages");
    await expect(
      page.getByRole("heading", { name: /messages/i }),
    ).toBeVisible();
  });

  test("should show empty state when no conversations exist", async ({
    page,
  }) => {
    // The default mock returns empty arrays, so empty state should show
    await page.goto("/messages");
    await expect(page.getByText(/no conversations yet/i)).toBeVisible();
  });

  test("should display conversation list with conversations", async ({
    page,
  }) => {
    // Override the conversations endpoint with mock data
    await page.route(
      `${API_BASE}/api/messaging/conversations/`,
      async (route) => {
        if (route.request().method() === "GET") {
          await route.fulfill({
            status: 200,
            contentType: "application/json",
            body: JSON.stringify({ count: MOCK_CONVERSATIONS.length, next: null, previous: null, results: MOCK_CONVERSATIONS }),
          });
        } else {
          await route.fallback();
        }
      },
    );

    await page.goto("/messages");

    // Should show both conversation participants
    await expect(page.getByText("Jane Doe")).toBeVisible();
    await expect(page.getByText("John Smith")).toBeVisible();

    // Should show message previews
    await expect(
      page.getByText("Hey, how is your progress?"),
    ).toBeVisible();
    await expect(page.getByText("Great workout today!")).toBeVisible();
  });

  test("should show chat view when selecting a conversation", async ({
    page,
  }) => {
    // Mock conversations
    await page.route(
      `${API_BASE}/api/messaging/conversations/`,
      async (route) => {
        if (route.request().method() === "GET") {
          await route.fulfill({
            status: 200,
            contentType: "application/json",
            body: JSON.stringify({ count: MOCK_CONVERSATIONS.length, next: null, previous: null, results: MOCK_CONVERSATIONS }),
          });
        } else {
          await route.fallback();
        }
      },
    );

    // Mock messages for conversation 1
    await page.route(
      `${API_BASE}/api/messaging/conversations/1/messages/*`,
      async (route) => {
        await route.fulfill({
          status: 200,
          contentType: "application/json",
          body: JSON.stringify(MOCK_MESSAGES),
        });
      },
    );

    // Mock mark-read
    await page.route(
      `${API_BASE}/api/messaging/conversations/1/read/`,
      async (route) => {
        await route.fulfill({
          status: 200,
          contentType: "application/json",
          body: JSON.stringify({ status: "ok" }),
        });
      },
    );

    await page.goto("/messages");

    // First conversation should be auto-selected, showing messages
    await expect(page.getByText("Going great, thanks!")).toBeVisible();

    // Should show the chat header with trainee name
    await expect(page.getByText("jane@test.com")).toBeVisible();
  });

  test("should have a message input area", async ({ page }) => {
    // Mock conversations
    await page.route(
      `${API_BASE}/api/messaging/conversations/`,
      async (route) => {
        if (route.request().method() === "GET") {
          await route.fulfill({
            status: 200,
            contentType: "application/json",
            body: JSON.stringify({ count: MOCK_CONVERSATIONS.length, next: null, previous: null, results: MOCK_CONVERSATIONS }),
          });
        } else {
          await route.fallback();
        }
      },
    );

    // Mock messages
    await page.route(
      `${API_BASE}/api/messaging/conversations/1/messages/*`,
      async (route) => {
        await route.fulfill({
          status: 200,
          contentType: "application/json",
          body: JSON.stringify(MOCK_MESSAGES),
        });
      },
    );

    // Mock mark-read
    await page.route(
      `${API_BASE}/api/messaging/conversations/1/read/`,
      async (route) => {
        await route.fulfill({
          status: 200,
          contentType: "application/json",
          body: JSON.stringify({ status: "ok" }),
        });
      },
    );

    await page.goto("/messages");

    // Should have a message input
    const input = page.getByLabel(/message input/i);
    await expect(input).toBeVisible();

    // Should have a send button
    const sendButton = page.getByLabel(/send message/i);
    await expect(sendButton).toBeVisible();
    await expect(sendButton).toBeDisabled(); // Disabled when input is empty
  });

  test("should enable send button when text is entered", async ({ page }) => {
    // Mock conversations
    await page.route(
      `${API_BASE}/api/messaging/conversations/`,
      async (route) => {
        if (route.request().method() === "GET") {
          await route.fulfill({
            status: 200,
            contentType: "application/json",
            body: JSON.stringify({ count: MOCK_CONVERSATIONS.length, next: null, previous: null, results: MOCK_CONVERSATIONS }),
          });
        } else {
          await route.fallback();
        }
      },
    );

    // Mock messages
    await page.route(
      `${API_BASE}/api/messaging/conversations/1/messages/*`,
      async (route) => {
        await route.fulfill({
          status: 200,
          contentType: "application/json",
          body: JSON.stringify(MOCK_MESSAGES),
        });
      },
    );

    // Mock mark-read
    await page.route(
      `${API_BASE}/api/messaging/conversations/1/read/`,
      async (route) => {
        await route.fulfill({
          status: 200,
          contentType: "application/json",
          body: JSON.stringify({ status: "ok" }),
        });
      },
    );

    await page.goto("/messages");

    const input = page.getByLabel(/message input/i);
    const sendButton = page.getByLabel(/send message/i);

    // Type a message
    await input.fill("Hello there!");

    // Send button should now be enabled
    await expect(sendButton).toBeEnabled();
  });
});

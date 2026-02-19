import { type Page, type Route } from "@playwright/test";

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8500";

interface MockOptions {
  status?: number;
  body?: unknown;
  delay?: number;
}

/**
 * Mock a specific API endpoint with a fixed response.
 */
export async function mockApiRoute(
  page: Page,
  urlPattern: string | RegExp,
  method: string,
  options: MockOptions = {},
): Promise<void> {
  const { status = 200, body = {}, delay = 0 } = options;

  await page.route(urlPattern, async (route: Route) => {
    if (route.request().method() !== method.toUpperCase()) {
      await route.fallback();
      return;
    }

    if (delay > 0) {
      await new Promise((resolve) => setTimeout(resolve, delay));
    }

    await route.fulfill({
      status,
      contentType: "application/json",
      body: JSON.stringify(body),
    });
  });
}

/**
 * Mock the login endpoint to return a successful JWT response.
 */
export async function mockLogin(page: Page, role: string): Promise<void> {
  await mockApiRoute(page, `${API_BASE}/api/auth/jwt/create/`, "POST", {
    body: {
      access: "mock-access-token",
      refresh: "mock-refresh-token",
    },
  });

  await mockApiRoute(page, `${API_BASE}/api/auth/users/me/`, "GET", {
    body: {
      id: 1,
      email: `${role}@test.com`,
      first_name: "Test",
      last_name: role.charAt(0).toUpperCase() + role.slice(1),
      role: role.toUpperCase(),
      is_active: true,
    },
  });
}

/**
 * Mock the dashboard stats endpoint.
 */
export async function mockDashboardStats(page: Page): Promise<void> {
  await mockApiRoute(
    page,
    `${API_BASE}/api/trainer/dashboard/stats/`,
    "GET",
    {
      body: {
        total_trainees: 12,
        active_trainees: 10,
        trainees_logged_today: 6,
        trainees_on_track: 8,
        avg_adherence_rate: 75,
        subscription_tier: "Pro",
        max_trainees: 50,
        trainees_pending_onboarding: 2,
      },
    },
  );
}

/**
 * Mock an API error response.
 */
export async function mockApiError(
  page: Page,
  urlPattern: string | RegExp,
  method: string,
  statusCode: number = 500,
  message: string = "Internal Server Error",
): Promise<void> {
  await mockApiRoute(page, urlPattern, method, {
    status: statusCode,
    body: { detail: message },
  });
}

/**
 * Mock a paginated list response.
 */
export async function mockPaginatedList<T>(
  page: Page,
  urlPattern: string | RegExp,
  items: T[],
): Promise<void> {
  await mockApiRoute(page, urlPattern, "GET", {
    body: {
      count: items.length,
      next: null,
      previous: null,
      results: items,
    },
  });
}

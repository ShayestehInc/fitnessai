import { type Page } from "@playwright/test";

export const TEST_USERS = {
  trainer: {
    email: "trainer@test.com",
    password: "TestPass123!",
    role: "TRAINER",
  },
  admin: {
    email: "admin@test.com",
    password: "AdminPass123!",
    role: "ADMIN",
  },
  ambassador: {
    email: "ambassador@test.com",
    password: "AmbassadorPass123!",
    role: "AMBASSADOR",
  },
} as const;

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8500";

// URLs that return paginated responses {count, next, previous, results}
const PAGINATED_PATTERNS = [
  "/trainees/",
  "/invitations/",
  "/notifications/",
  "/program-templates/",
  "/exercises/",
  "/announcements/",
  "/ambassadors/",
  "/trainers/",
  "/users/",
  "/subscriptions/",
  "/tiers/",
  "/coupons/",
  "/connections/",
  "/events/",
  "/features/",
];

// URLs that return array responses
const ARRAY_PATTERNS = [
  "/referrals/",
  "/payouts/",
  "/payment-history/",
  "/change-history/",
];

// Default mock data for specific endpoint patterns
// IMPORTANT: More specific patterns must come before generic ones
function getMockResponseForUrl(url: string): unknown {
  // Auth endpoints are handled separately
  if (url.includes("/api/auth/")) return {};

  // --- Specific endpoints (check BEFORE generic patterns) ---

  // AI providers (returns array)
  if (url.includes("/ai/providers")) {
    return [{ id: 1, name: "openai", is_configured: true }];
  }

  // AI chat
  if (url.includes("/ai/chat")) {
    return { response: "Hello! How can I help you?" };
  }

  // Admin past-due (returns array, NOT paginated)
  if (url.includes("/admin/past-due")) {
    return [];
  }

  // Admin dashboard
  if (url.includes("/admin/dashboard")) {
    return {
      total_trainers: 3,
      total_trainees: 10,
      total_revenue: "1000.00",
      active_subscriptions: 2,
      past_due_count: 0,
      tier_breakdown: { FREE: 1, PRO: 2 },
      recent_signups: [],
    };
  }

  // Ambassador dashboard (must be checked before generic /dashboard/)
  if (url.includes("/ambassador/dashboard")) {
    return {
      total_earnings: "250.00",
      total_referrals: 3,
      commission_rate: 10,
      monthly_earnings: [{ month: "2026-02", amount: "100.00" }],
      recent_referrals: [],
      referral_code: "TESTCODE",
    };
  }

  // Ambassador connect status
  if (url.includes("/ambassador/connect/status")) {
    return { has_account: false, payouts_enabled: false };
  }

  // Trainer dashboard stats
  if (url.includes("/dashboard/stats")) {
    return {
      total_trainees: 5,
      active_trainees: 3,
      trainees_logged_today: 2,
      trainees_on_track: 4,
      avg_adherence_rate: 75,
      subscription_tier: "Pro",
      max_trainees: 50,
      trainees_pending_onboarding: 1,
    };
  }

  // Trainer dashboard overview
  if (url.includes("/dashboard/")) {
    return {
      recent_trainees: [],
      inactive_trainees: [],
      total_trainees: 5,
      active_trainees: 3,
      trainees_logged_today: 2,
      trainees_on_track: 4,
      avg_adherence_rate: 75,
      subscription_tier: "Pro",
      max_trainees: 50,
      trainees_pending_onboarding: 1,
    };
  }

  // Stripe Connect status (trainer)
  if (url.includes("/connect/status")) {
    return { has_account: false, payouts_enabled: false, charges_enabled: false };
  }

  // Pricing / subscription plans
  if (url.includes("/pricing/")) {
    return {
      tier_name: "Pro",
      price: "29.00",
      next_payment_date: null,
      features: ["Unlimited trainees", "AI assistant", "Custom branding"],
    };
  }

  // Branding
  if (url.includes("/branding/")) {
    return { primary_color: "#000000", secondary_color: "#ffffff", app_name: "FitnessAI" };
  }

  // Unread count
  if (url.includes("/unread-count")) {
    return { count: 0 };
  }

  // Leaderboard settings (returns an array of settings)
  if (url.includes("/leaderboard-settings")) {
    return [];
  }

  // Referral code
  if (url.includes("/referral-code/")) {
    return { referral_code: "TESTCODE" };
  }

  // --- Generic patterns ---

  // Paginated list endpoints
  for (const pattern of PAGINATED_PATTERNS) {
    if (url.includes(pattern)) {
      return { count: 0, next: null, previous: null, results: [] };
    }
  }

  // Array endpoints
  for (const pattern of ARRAY_PATTERNS) {
    if (url.includes(pattern)) {
      return [];
    }
  }

  // Default: empty object
  return {};
}

/**
 * Log in as a specific role by mocking the auth API endpoints
 * and injecting tokens directly. This avoids rate limiting and
 * makes tests faster and deterministic.
 */
export async function loginAs(
  page: Page,
  role: keyof typeof TEST_USERS,
): Promise<void> {
  const user = TEST_USERS[role];

  const expectedPath =
    role === "admin"
      ? "/admin/dashboard"
      : role === "ambassador"
        ? "/ambassador/dashboard"
        : "/dashboard";

  // Mock the JWT creation endpoint
  await page.route(`${API_BASE}/api/auth/jwt/create/`, async (route) => {
    if (route.request().method() !== "POST") {
      await route.fallback();
      return;
    }
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        access: `mock-access-token-${role}`,
        refresh: `mock-refresh-token-${role}`,
      }),
    });
  });

  // Mock the users/me endpoint
  await page.route(`${API_BASE}/api/auth/users/me/`, async (route) => {
    if (route.request().method() !== "GET") {
      await route.fallback();
      return;
    }
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        id: 1,
        email: user.email,
        first_name: "Test",
        last_name: role.charAt(0).toUpperCase() + role.slice(1),
        role: user.role,
        is_active: true,
      }),
    });
  });

  // Catch-all mock for remaining API calls
  await page.route(`${API_BASE}/api/**`, async (route) => {
    const url = route.request().url();
    // Let the mocked auth endpoints through
    if (
      url.includes("/api/auth/jwt/create/") ||
      url.includes("/api/auth/users/me/")
    ) {
      await route.fallback();
      return;
    }

    const mockData = getMockResponseForUrl(url);
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(mockData),
    });
  });

  // Navigate to login page, fill form, submit
  await page.goto("/login");
  await page.getByLabel("Email").fill(user.email);
  await page.getByLabel("Password").fill(user.password);
  await page.getByRole("button", { name: /sign in/i }).click();

  // Wait for redirect after successful (mocked) login
  await page.waitForURL(`**${expectedPath}`, { timeout: 15000 });
}

export async function logout(page: Page): Promise<void> {
  // Open user menu and click sign out
  await page.getByRole("button", { name: /user menu/i }).click();
  await page.getByRole("menuitem", { name: /sign out/i }).click();
  await page.waitForURL("**/login", { timeout: 10000 });
}

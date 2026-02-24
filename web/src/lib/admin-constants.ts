/**
 * Shared UI constants for the admin dashboard.
 * Centralised here to avoid duplication across components.
 */

// ---------- Tier badge colours ----------

export const TIER_COLORS: Record<string, string> = {
  FREE: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300",
  STARTER: "bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300",
  PRO: "bg-purple-100 text-purple-700 dark:bg-purple-900 dark:text-purple-300",
  ENTERPRISE:
    "bg-amber-100 text-amber-700 dark:bg-amber-900 dark:text-amber-300",
} as const;

// ---------- Subscription status → badge variant ----------

export const SUBSCRIPTION_STATUS_VARIANT: Record<
  string,
  "default" | "secondary" | "destructive" | "outline"
> = {
  active: "default",
  past_due: "destructive",
  canceled: "secondary",
  trialing: "outline",
  suspended: "secondary",
} as const;

// ---------- Coupon status → badge variant ----------

export const COUPON_STATUS_VARIANT: Record<
  string,
  "default" | "secondary" | "destructive" | "outline"
> = {
  active: "default",
  expired: "secondary",
  revoked: "destructive",
  exhausted: "outline",
} as const;

// ---------- Shared select class string ----------

/** Standard Tailwind class string for native <select> elements
 *  matching the project's Input component styling. */
export const SELECT_CLASSES =
  "flex h-11 rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring sm:h-9" as const;

export const SELECT_CLASSES_FULL_WIDTH = `${SELECT_CLASSES} w-full` as const;

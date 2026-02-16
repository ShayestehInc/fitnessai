// ============ Admin Dashboard ============

export interface AdminDashboardStats {
  total_trainers: number;
  active_trainers: number;
  total_trainees: number;
  tier_breakdown: Record<string, number>;
  status_breakdown: Record<string, number>;
  monthly_recurring_revenue: string;
  total_past_due: string;
  payments_due_today: number;
  payments_due_this_week: number;
  payments_due_this_month: number;
  past_due_count: number;
}

// ============ Admin Trainers ============

export interface AdminTrainerSubscription {
  id: number | null;
  tier: string | null;
  status: string | null;
  next_payment_date: string | null;
  past_due_amount: string;
}

export interface AdminTrainerListItem {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  is_active: boolean;
  created_at: string;
  trainee_count: number;
  subscription: AdminTrainerSubscription | null;
}

// ============ Admin Subscriptions ============

export interface AdminTrainerSummary {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  is_active: boolean;
  created_at: string;
  trainee_count: number;
}

export interface AdminPaymentHistory {
  id: number;
  amount: string;
  status: string;
  description: string;
  failure_reason: string;
  payment_date: string;
  stripe_payment_intent_id: string | null;
}

export interface AdminSubscriptionChange {
  id: number;
  change_type: string;
  from_tier: string;
  to_tier: string;
  from_status: string;
  to_status: string;
  changed_by_email: string;
  reason: string;
  created_at: string;
}

export interface AdminSubscription {
  id: number;
  trainer: AdminTrainerSummary;
  tier: string;
  status: string;
  trainee_count: number;
  max_trainees: number;
  monthly_price: string;
  stripe_subscription_id: string | null;
  stripe_customer_id: string | null;
  current_period_start: string | null;
  current_period_end: string | null;
  next_payment_date: string | null;
  last_payment_date: string | null;
  last_payment_amount: string | null;
  past_due_amount: string;
  past_due_since: string | null;
  failed_payment_count: number;
  days_until_payment: number | null;
  days_past_due: number | null;
  trial_start: string | null;
  trial_end: string | null;
  trial_used: boolean;
  admin_notes: string;
  created_at: string;
  updated_at: string;
  recent_payments: AdminPaymentHistory[];
  recent_changes: AdminSubscriptionChange[];
}

export interface AdminSubscriptionListItem {
  id: number;
  trainer_email: string;
  trainer_name: string;
  tier: string;
  status: string;
  trainee_count: number;
  max_trainees: number;
  monthly_price: string;
  next_payment_date: string | null;
  past_due_amount: string;
  past_due_since: string | null;
  days_until_payment: number | null;
  days_past_due: number | null;
  created_at: string;
}

// ============ Admin Tiers ============

export interface AdminSubscriptionTier {
  id: number;
  name: string;
  display_name: string;
  description: string;
  price: string;
  trainee_limit: number;
  trainee_limit_display: string;
  features: string[];
  stripe_price_id: string;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface CreateTierPayload {
  name: string;
  display_name: string;
  description: string;
  price: string;
  trainee_limit: number;
  features: string[];
  stripe_price_id: string;
  is_active: boolean;
  sort_order: number;
}

export type UpdateTierPayload = CreateTierPayload;

// ============ Admin Coupons ============

export interface AdminCouponUsage {
  id: number;
  user_email: string;
  user_name: string;
  discount_amount: string;
  used_at: string;
}

export interface AdminCoupon {
  id: number;
  code: string;
  description: string;
  coupon_type: string;
  discount_value: string;
  applies_to: string;
  status: string;
  created_by_trainer: number | null;
  created_by_trainer_email: string | null;
  created_by_admin: number | null;
  created_by_admin_email: string | null;
  applicable_tiers: string[];
  max_uses: number;
  max_uses_per_user: number;
  current_uses: number;
  usage_count: number;
  valid_from: string;
  valid_until: string | null;
  stripe_coupon_id: string;
  is_currently_valid: boolean;
  recent_usages: AdminCouponUsage[];
  created_at: string;
  updated_at: string;
}

export interface AdminCouponListItem {
  id: number;
  code: string;
  description: string;
  coupon_type: string;
  discount_value: string;
  applies_to: string;
  status: string;
  max_uses: number;
  current_uses: number;
  valid_from: string;
  valid_until: string | null;
  is_currently_valid: boolean;
  created_by_name: string;
  created_at: string;
}

export interface CreateCouponPayload {
  code: string;
  description: string;
  coupon_type: string;
  discount_value: string;
  applies_to: string;
  applicable_tiers: string[];
  max_uses: number;
  max_uses_per_user: number;
  valid_from: string;
  valid_until: string | null;
}

export interface UpdateCouponPayload {
  description?: string;
  discount_value?: string;
  applicable_tiers?: string[];
  max_uses?: number;
  max_uses_per_user?: number;
  valid_until?: string | null;
}

// ============ Admin Users ============

export interface AdminUser {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  role: string;
  is_active: boolean;
  created_at: string;
  trainee_count: number;
}

export interface CreateUserPayload {
  email: string;
  password: string;
  role: string;
  first_name: string;
  last_name: string;
}

export interface UpdateUserPayload {
  first_name?: string;
  last_name?: string;
  is_active?: boolean;
  role?: string;
  password?: string;
}

// ============ Impersonation ============

export interface ImpersonationResponse {
  access: string;
  refresh: string;
  trainer: {
    id: number;
    email: string;
    first_name: string;
    last_name: string;
    role: string;
  };
  message: string;
}

export interface EndImpersonationResponse {
  message: string;
  return_to_admin: boolean;
}

// ============ Shared Constants ============

export const TIER_COLORS: Record<string, string> = {
  FREE: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300",
  STARTER: "bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300",
  PRO: "bg-purple-100 text-purple-700 dark:bg-purple-900 dark:text-purple-300",
  ENTERPRISE:
    "bg-amber-100 text-amber-700 dark:bg-amber-900 dark:text-amber-300",
} as const;

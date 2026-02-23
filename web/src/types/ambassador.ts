// Admin-facing ambassador types
export interface Ambassador {
  id: number;
  user: {
    id: number;
    email: string;
    first_name: string;
    last_name: string;
    is_active: boolean;
    created_at: string;
  };
  referral_code: string;
  commission_rate: number;
  total_earnings: string;
  pending_earnings: string;
  total_referrals: number;
  active_referrals: number;
  is_active: boolean;
  stripe_connect_status: string;
  created_at: string;
}

export interface AmbassadorReferral {
  id: number;
  trainer: {
    id: number;
    email: string;
    first_name: string;
    last_name: string;
    is_active: boolean;
    created_at: string;
  };
  referral_code_used: string;
  status: string;
  referred_at: string;
  activated_at: string | null;
  churned_at: string | null;
  trainer_subscription_tier: string;
  total_commission_earned: string;
}

export interface AmbassadorCommission {
  id: number;
  trainer_email: string;
  commission_rate: number;
  base_amount: string;
  commission_amount: string;
  status: string;
  period_start: string;
  period_end: string;
  created_at: string;
}

export interface CreateAmbassadorPayload {
  email: string;
  first_name: string;
  last_name: string;
  password: string;
  commission_rate: number;
}

// Ambassador self-service types
export interface AmbassadorDashboardData {
  total_earnings: string;
  pending_earnings: string;
  commission_rate: number;
  referral_code: string;
  is_active: boolean;
  total_referrals: number;
  active_referrals: number;
  pending_referrals: number;
  churned_referrals: number;
  monthly_earnings: { month: string; amount: string }[];
  recent_referrals: AmbassadorReferral[];
}

export interface AmbassadorSelfReferral {
  id: number;
  trainer: {
    id: number;
    email: string;
    first_name: string;
    last_name: string;
    is_active: boolean;
    created_at: string;
  };
  referral_code_used: string;
  status: string;
  referred_at: string;
  activated_at: string | null;
  churned_at: string | null;
  trainer_subscription_tier: string;
  total_commission_earned: string;
}

export interface AmbassadorPayout {
  id: number;
  amount: string;
  status: string;
  stripe_transfer_id: string | null;
  error_message: string | null;
  commission_count: number;
  created_at: string;
}

export interface AmbassadorConnectStatus {
  has_account: boolean;
  charges_enabled: boolean;
  payouts_enabled: boolean;
  details_submitted: boolean;
}

// Ambassador admin (scoped) types
export interface AmbassadorAdminDashboardData {
  total_trainers: number;
  active_trainers: number;
  total_trainees: number;
  tier_breakdown: Record<string, number>;
  monthly_recurring_revenue: string;
  referral_code: string;
  commission_rate: string;
}

export interface AmbassadorAdminTrainer {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  is_active: boolean;
  created_at: string;
  trainee_count: number;
  subscription: {
    id: number | null;
    tier: string | null;
    status: string | null;
  } | null;
}

export interface CreateTrainerPayload {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
}

export interface AmbassadorAdminImpersonationResponse {
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

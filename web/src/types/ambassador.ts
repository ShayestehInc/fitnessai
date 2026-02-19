// Admin-facing ambassador types
export interface Ambassador {
  id: number;
  user: {
    id: number;
    email: string;
    first_name: string;
    last_name: string;
    is_active: boolean;
  };
  referral_code: string;
  commission_rate: number;
  total_earnings: string;
  pending_earnings: string;
  total_referrals: number;
  active_referrals: number;
  is_active: boolean;
  stripe_connect_status: string;
}

export interface AmbassadorReferral {
  id: number;
  trainer: {
    name: string;
    email: string;
  };
  status: string;
  tier: string;
  commission_earned: string;
  referred_at: string;
}

export interface AmbassadorCommission {
  id: number;
  month: string;
  trainer_name: string;
  amount: string;
  status: string;
  rate_snapshot: number;
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
  recent_referrals: {
    trainer: { first_name: string; last_name: string; email: string };
    status: string;
    referred_at: string;
  }[];
}

export interface AmbassadorSelfReferral {
  id: number;
  trainer_name: string;
  trainer_email: string;
  status: string;
  tier: string;
  commission_earned: string;
  referred_at: string;
}

export interface AmbassadorPayout {
  id: number;
  amount: string;
  date: string;
  status: string;
  transfer_id: string | null;
}

export interface AmbassadorConnectStatus {
  has_account: boolean;
  charges_enabled: boolean;
  payouts_enabled: boolean;
  details_submitted: boolean;
}

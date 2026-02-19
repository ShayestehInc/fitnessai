export interface StripeConnectStatus {
  has_account: boolean;
  charges_enabled: boolean;
  payouts_enabled: boolean;
  details_submitted: boolean;
}

export interface TrainerPayment {
  id: number;
  amount: string;
  status: string;
  description: string;
  payment_date: string;
}

export interface TrainerSubscriber {
  id: number;
  trainee_name: string;
  plan: string;
  status: string;
  last_payment_date: string | null;
}

export interface TrainerPricing {
  tier_name: string;
  price: string;
  features: string[];
  trainee_limit: number;
  next_payment_date: string | null;
}

export type RetentionPeriod = 7 | 14 | 30;

export type RiskTier = "critical" | "high" | "medium" | "low";

export interface TraineeEngagement {
  trainee_id: number;
  trainee_email: string;
  trainee_name: string;
  engagement_score: number;
  churn_risk_score: number;
  risk_tier: RiskTier;
  days_since_last_activity: number | null;
  workout_consistency: number;
  nutrition_consistency: number;
  last_active_date: string | null;
}

export interface RetentionSummary {
  total_trainees: number;
  at_risk_count: number;
  critical_count: number;
  high_count: number;
  medium_count: number;
  low_count: number;
  avg_engagement: number;
  retention_rate: number;
}

export interface RetentionTrendPoint {
  date: string;
  avg_engagement: number;
  at_risk_count: number;
  total_trainees: number;
}

export interface RetentionAnalytics {
  period_days: number;
  summary: RetentionSummary;
  trainees: TraineeEngagement[];
  trends: RetentionTrendPoint[];
}

export interface AtRiskResponse {
  period_days: number;
  at_risk_count: number;
  trainees: TraineeEngagement[];
}

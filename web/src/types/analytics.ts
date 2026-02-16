export interface TraineeAdherence {
  trainee_id: number;
  trainee_email: string;
  trainee_name: string;
  adherence_rate: number;
  days_tracked: number;
}

export interface AdherenceAnalytics {
  period_days: number;
  total_tracking_days: number;
  food_logged_rate: number;
  workout_logged_rate: number;
  protein_goal_rate: number;
  trainee_adherence: TraineeAdherence[];
}

export interface TraineeProgressEntry {
  trainee_id: number;
  trainee_email: string;
  trainee_name: string;
  current_weight: number | null;
  weight_change: number | null;
  goal: string | null;
}

export interface ProgressAnalytics {
  trainee_progress: TraineeProgressEntry[];
}

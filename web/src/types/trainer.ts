export interface DashboardStats {
  total_trainees: number;
  active_trainees: number;
  trainees_logged_today: number;
  trainees_on_track: number;
  avg_adherence_rate: number;
  subscription_tier: string;
  max_trainees: number;
  trainees_pending_onboarding: number;
}

export interface TraineeProgram {
  id: number;
  name: string;
  start_date: string;
  end_date: string | null;
  is_active?: boolean;
}

export interface TraineeListItem {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  profile_complete: boolean;
  last_activity: string | null;
  current_program: TraineeProgram | null;
  is_active: boolean;
  created_at: string;
}

export interface TraineeProfile {
  sex: string | null;
  age: number | null;
  height_cm: number | null;
  weight_kg: number | null;
  activity_level: string;
  goal: string;
  diet_type: string;
  meals_per_day: number;
  onboarding_completed: boolean;
}

export interface NutritionGoal {
  protein_goal: number;
  carbs_goal: number;
  fat_goal: number;
  calories_goal: number;
  is_trainer_adjusted: boolean;
}

export interface RecentActivity {
  date: string;
  logged_food: boolean;
  logged_workout: boolean;
  calories_consumed: number;
  protein_consumed: number;
  hit_protein_goal: boolean;
}

export interface TraineeDetail {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  phone_number: string | null;
  is_active: boolean;
  created_at: string;
  profile: TraineeProfile | null;
  nutrition_goal: NutritionGoal | null;
  programs: TraineeProgram[];
  recent_activity: RecentActivity[];
}

export interface DashboardOverview {
  recent_trainees: TraineeListItem[];
  inactive_trainees: TraineeListItem[];
  today: string;
}

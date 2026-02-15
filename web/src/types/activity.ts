export interface ActivitySummary {
  id: number;
  date: string;
  workouts_completed: number;
  total_sets: number;
  total_volume: number;
  calories_consumed: number;
  protein_consumed: number;
  carbs_consumed: number;
  fat_consumed: number;
  logged_food: boolean;
  logged_workout: boolean;
  hit_protein_goal: boolean;
  hit_calorie_goal: boolean;
  steps: number;
  sleep_hours: number;
}

// Types for trainee-facing API responses used in the impersonation trainee view

export interface ImpersonationStartResponse {
  access: string;
  refresh: string;
  session: {
    id: number;
    trainer: number;
    trainee: number;
    is_read_only: boolean;
    started_at: string;
    ended_at: string | null;
  };
  trainee: {
    id: number;
    email: string;
    first_name: string;
    last_name: string;
  };
}

export interface TraineeViewProgram {
  id: number;
  trainee: number;
  trainee_email: string;
  trainee_name: string;
  name: string;
  description: string;
  start_date: string;
  end_date: string | null;
  schedule: TraineeViewSchedule | null;
  is_active: boolean;
  image_url: string | null;
  duration_weeks: number | null;
  difficulty_level: string | null;
  goal_type: string | null;
  created_by: number;
  created_by_email: string;
  created_at: string;
  updated_at: string;
}

export interface TraineeViewSchedule {
  weeks: TraineeViewScheduleWeek[];
}

export interface TraineeViewScheduleWeek {
  week_number: number;
  days: TraineeViewScheduleDay[];
}

export interface TraineeViewScheduleDay {
  day: string;
  name?: string;
  is_rest_day?: boolean;
  exercises: TraineeViewScheduleExercise[];
}

export interface TraineeViewScheduleExercise {
  exercise_id: number;
  exercise_name: string;
  sets: number;
  reps: number | string;
  weight: number;
  unit: "lbs" | "kg";
  rest_seconds: number;
}

export interface MacroValues {
  protein: number;
  carbs: number;
  fat: number;
  calories: number;
}

export interface NutritionSummary {
  date: string;
  goals: MacroValues;
  consumed: MacroValues;
  remaining: MacroValues;
  meals: NutritionMeal[];
  per_meal_targets: {
    protein: number;
    carbs: number;
    fat: number;
  };
}

export interface NutritionMeal {
  name: string;
  protein: number;
  carbs: number;
  fat: number;
  calories: number;
  timestamp: string | null;
}

export interface TraineeWeightCheckIn {
  id: number;
  trainee: number;
  trainee_email: string;
  date: string;
  weight_kg: number;
  notes: string;
  created_at: string;
}

export interface TrainerImpersonationState {
  trainerAccessToken: string;
  trainerRefreshToken: string;
  traineeId: number;
  traineeName: string;
}

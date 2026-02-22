// Types for the trainee web dashboard

export interface WeeklyProgress {
  total_days: number;
  completed_days: number;
  percentage: number;
}

export interface LatestWeightCheckIn {
  id: number;
  trainee: number;
  date: string;
  weight_kg: number;
  notes: string;
  created_at: string;
}

export interface Announcement {
  id: number;
  trainer: number;
  title: string;
  content: string;
  is_pinned: boolean;
  is_read: boolean;
  created_at: string;
  updated_at: string;
}

export interface AnnouncementUnreadCount {
  unread_count: number;
}

export interface Achievement {
  id: number;
  name: string;
  description: string;
  icon: string;
  criteria_type: string;
  criteria_value: number;
  earned: boolean;
  earned_at: string | null;
  progress: number;
}

// Workout history types (from GET /api/workouts/daily-logs/workout-history/)
export interface WorkoutHistoryItem {
  id: number;
  date: string;
  workout_name: string;
  exercise_count: number;
  total_sets: number;
  total_volume_lbs: number;
  duration_display: string;
}

export interface WorkoutHistoryResponse {
  count: number;
  next: string | null;
  previous: string | null;
  results: WorkoutHistoryItem[];
}

// Workout detail (from GET /api/workouts/daily-logs/{id}/workout-detail/)
export interface WorkoutDetailData {
  id: number;
  date: string;
  workout_data: WorkoutData;
  notes: string;
}

export interface WorkoutData {
  workout_name?: string;
  duration?: string;
  exercises?: WorkoutExerciseLog[];
  sessions?: WorkoutSession[];
}

export interface WorkoutSession {
  workout_name?: string;
  duration?: string;
  exercises?: WorkoutExerciseLog[];
}

export interface WorkoutExerciseLog {
  exercise_id: number;
  exercise_name: string;
  sets: WorkoutSetLog[];
  timestamp?: string;
}

export interface WorkoutSetLog {
  set_number: number;
  reps: number;
  weight: number;
  unit: string;
  completed: boolean;
}

// Weight check-in creation payload
export interface CreateWeightCheckInPayload {
  date: string;
  weight_kg: number;
  notes?: string;
}

// Daily log creation payload (for saving workouts)
export interface SaveWorkoutPayload {
  date: string;
  workout_data: {
    workout_name: string;
    duration: string;
    exercises: WorkoutExerciseLog[];
  };
}


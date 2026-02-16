export const DifficultyLevel = {
  BEGINNER: "beginner",
  INTERMEDIATE: "intermediate",
  ADVANCED: "advanced",
} as const;

export type DifficultyLevel =
  (typeof DifficultyLevel)[keyof typeof DifficultyLevel];

export const DIFFICULTY_LABELS: Record<DifficultyLevel, string> = {
  beginner: "Beginner",
  intermediate: "Intermediate",
  advanced: "Advanced",
};

export const GoalType = {
  BUILD_MUSCLE: "build_muscle",
  FAT_LOSS: "fat_loss",
  STRENGTH: "strength",
  ENDURANCE: "endurance",
  RECOMP: "recomp",
  GENERAL_FITNESS: "general_fitness",
} as const;

export type GoalType = (typeof GoalType)[keyof typeof GoalType];

export const GOAL_LABELS: Record<GoalType, string> = {
  build_muscle: "Build Muscle",
  fat_loss: "Fat Loss",
  strength: "Strength",
  endurance: "Endurance",
  recomp: "Body Recomposition",
  general_fitness: "General Fitness",
};

export const MuscleGroup = {
  CHEST: "chest",
  BACK: "back",
  SHOULDERS: "shoulders",
  ARMS: "arms",
  LEGS: "legs",
  GLUTES: "glutes",
  CORE: "core",
  CARDIO: "cardio",
  FULL_BODY: "full_body",
  OTHER: "other",
} as const;

export type MuscleGroup = (typeof MuscleGroup)[keyof typeof MuscleGroup];

export const MUSCLE_GROUP_LABELS: Record<MuscleGroup, string> = {
  chest: "Chest",
  back: "Back",
  shoulders: "Shoulders",
  arms: "Arms",
  legs: "Legs",
  glutes: "Glutes",
  core: "Core",
  cardio: "Cardio",
  full_body: "Full Body",
  other: "Other",
};

export const DAY_NAMES = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
] as const;

// --- Schedule JSON types ---

export interface ScheduleExercise {
  exercise_id: number;
  exercise_name: string;
  sets: number;
  reps: number | string;
  weight: number;
  unit: "lbs" | "kg";
  rest_seconds: number;
}

export interface ScheduleDay {
  day: string;
  name: string;
  is_rest_day: boolean;
  exercises: ScheduleExercise[];
}

export interface ScheduleWeek {
  week_number: number;
  days: ScheduleDay[];
}

export interface Schedule {
  weeks: ScheduleWeek[];
}

// --- API response types ---

export interface Exercise {
  id: number;
  name: string;
  description: string;
  video_url: string | null;
  image_url: string | null;
  muscle_group: MuscleGroup;
  is_public: boolean;
  created_by: number | null;
  created_at: string;
  updated_at: string;
}

export interface ProgramTemplate {
  id: number;
  name: string;
  description: string;
  duration_weeks: number;
  schedule_template: Schedule | null;
  nutrition_template: Record<string, unknown> | null;
  difficulty_level: DifficultyLevel | null;
  goal_type: GoalType | null;
  image_url: string | null;
  is_public: boolean;
  created_by: number;
  created_by_email: string;
  times_used: number;
  created_at: string;
  updated_at: string;
}

// --- Payload types ---

export interface CreateProgramPayload {
  name: string;
  description?: string;
  duration_weeks: number;
  schedule_template: Schedule;
  difficulty_level?: DifficultyLevel;
  goal_type?: GoalType;
  is_public?: boolean;
}

export interface UpdateProgramPayload {
  name?: string;
  description?: string;
  duration_weeks?: number;
  schedule_template?: Schedule;
  difficulty_level?: DifficultyLevel | null;
  goal_type?: GoalType | null;
}

export interface AssignProgramPayload {
  trainee_id: number;
  start_date: string;
}

export const DifficultyLevel = {
  BEGINNER: "BEGINNER",
  INTERMEDIATE: "INTERMEDIATE",
  ADVANCED: "ADVANCED",
} as const;

export type DifficultyLevel =
  (typeof DifficultyLevel)[keyof typeof DifficultyLevel];

export const DIFFICULTY_LABELS: Record<DifficultyLevel, string> = {
  BEGINNER: "Beginner",
  INTERMEDIATE: "Intermediate",
  ADVANCED: "Advanced",
};

export const GoalType = {
  BUILD_MUSCLE: "BUILD_MUSCLE",
  FAT_LOSS: "FAT_LOSS",
  STRENGTH: "STRENGTH",
  ENDURANCE: "ENDURANCE",
  RECOMP: "RECOMP",
  GENERAL_FITNESS: "GENERAL_FITNESS",
} as const;

export type GoalType = (typeof GoalType)[keyof typeof GoalType];

export const GOAL_LABELS: Record<GoalType, string> = {
  BUILD_MUSCLE: "Build Muscle",
  FAT_LOSS: "Fat Loss",
  STRENGTH: "Strength",
  ENDURANCE: "Endurance",
  RECOMP: "Body Recomposition",
  GENERAL_FITNESS: "General Fitness",
};

export const MuscleGroup = {
  CHEST: "CHEST",
  BACK: "BACK",
  SHOULDERS: "SHOULDERS",
  ARMS: "ARMS",
  LEGS: "LEGS",
  GLUTES: "GLUTES",
  CORE: "CORE",
  CARDIO: "CARDIO",
  FULL_BODY: "FULL_BODY",
  OTHER: "OTHER",
} as const;

export type MuscleGroup = (typeof MuscleGroup)[keyof typeof MuscleGroup];

export const MUSCLE_GROUP_LABELS: Record<MuscleGroup, string> = {
  CHEST: "Chest",
  BACK: "Back",
  SHOULDERS: "Shoulders",
  ARMS: "Arms",
  LEGS: "Legs",
  GLUTES: "Glutes",
  CORE: "Core",
  CARDIO: "Cardio",
  FULL_BODY: "Full Body",
  OTHER: "Other",
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
  difficulty_level: DifficultyLevel | null;
  goal_type: GoalType | null;
  image_url: string | null;
  is_public: boolean;
  created_by: number;
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

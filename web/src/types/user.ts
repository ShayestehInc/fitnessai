export const UserRole = {
  ADMIN: "ADMIN",
  TRAINER: "TRAINER",
  TRAINEE: "TRAINEE",
  AMBASSADOR: "AMBASSADOR",
} as const;

export type UserRole = (typeof UserRole)[keyof typeof UserRole];

export interface TrainerInfo {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  profile_image: string | null;
}

export interface User {
  id: number;
  email: string;
  role: UserRole;
  first_name: string;
  last_name: string;
  business_name: string | null;
  is_active: boolean;
  onboarding_completed: boolean;
  trainer: TrainerInfo | null;
  profile_image: string | null;
}

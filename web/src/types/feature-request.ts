export type FeatureRequestStatus =
  | "submitted"
  | "under_review"
  | "planned"
  | "in_development"
  | "released"
  | "declined";

export type FeatureRequestCategory =
  | "trainer_tools"
  | "trainee_app"
  | "nutrition"
  | "workouts"
  | "analytics"
  | "integrations"
  | "other";

export interface FeatureRequest {
  id: number;
  title: string;
  description: string;
  category: FeatureRequestCategory;
  status: FeatureRequestStatus;
  submitted_by: number | null;
  submitted_by_email: string;
  submitted_by_name: string;
  upvotes: number;
  downvotes: number;
  vote_score: number;
  user_vote: "up" | "down" | null;
  comment_count: number;
  created_at: string;
  updated_at: string;
}

export interface FeatureComment {
  id: number;
  feature: number;
  user: number | null;
  user_email: string;
  user_name: string;
  content: string;
  is_admin_response: boolean;
  created_at: string;
  updated_at: string;
}

export interface FeatureRequestDetail extends FeatureRequest {
  public_response: string;
  target_release: string;
  comments: FeatureComment[];
}

export interface CreateFeatureRequestPayload {
  title: string;
  description: string;
  category: FeatureRequestCategory;
}

export const STATUS_LABELS: Record<FeatureRequestStatus, string> = {
  submitted: "Submitted",
  under_review: "Under Review",
  planned: "Planned",
  in_development: "In Development",
  released: "Released",
  declined: "Declined",
};

export const STATUS_COLORS: Record<FeatureRequestStatus, string> = {
  submitted: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-200",
  under_review: "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-200",
  planned: "bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-200",
  in_development: "bg-cyan-100 text-cyan-800 dark:bg-cyan-900/30 dark:text-cyan-200",
  released: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-200",
  declined: "bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-200",
};

export const CATEGORY_LABELS: Record<FeatureRequestCategory, string> = {
  trainer_tools: "Trainer Tools",
  trainee_app: "Trainee App",
  nutrition: "Nutrition",
  workouts: "Workouts",
  analytics: "Analytics",
  integrations: "Integrations",
  other: "Other",
};

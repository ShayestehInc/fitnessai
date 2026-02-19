export type FeatureRequestStatus = "open" | "planned" | "in_progress" | "done" | "closed";

export interface FeatureRequest {
  id: number;
  title: string;
  description: string;
  status: FeatureRequestStatus;
  vote_count: number;
  has_voted: boolean;
  comment_count: number;
  author_name: string;
  created_at: string;
}

export interface FeatureComment {
  id: number;
  author_name: string;
  content: string;
  created_at: string;
}

export interface CreateFeatureRequestPayload {
  title: string;
  description: string;
}

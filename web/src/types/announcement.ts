export interface Announcement {
  id: number;
  title: string;
  body: string;
  content_format: "plain" | "markdown";
  is_pinned: boolean;
  created_at: string;
  updated_at: string;
}

export interface CreateAnnouncementPayload {
  title: string;
  body: string;
  content_format: "plain" | "markdown";
  is_pinned: boolean;
}

export interface UpdateAnnouncementPayload {
  title?: string;
  body?: string;
  content_format?: "plain" | "markdown";
  is_pinned?: boolean;
}

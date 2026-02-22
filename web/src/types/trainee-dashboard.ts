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


export interface CalendarConnection {
  id: number;
  provider: "google" | "microsoft";
  status: "connected" | "disconnected" | "expired";
  email: string;
  created_at: string;
}

export interface CalendarEvent {
  id: number;
  title: string;
  start_time: string;
  end_time: string;
  calendar_provider: "google" | "microsoft";
}

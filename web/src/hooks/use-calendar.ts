"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { CalendarConnection, CalendarEvent } from "@/types/calendar";

export function useCalendarConnections() {
  return useQuery<CalendarConnection[]>({
    queryKey: ["calendar-connections"],
    queryFn: () =>
      apiClient.get<CalendarConnection[]>(API_URLS.CALENDAR_CONNECTIONS),
  });
}

export function useGoogleCalendarAuth() {
  return useMutation({
    mutationFn: () =>
      apiClient.get<{ url: string }>(API_URLS.GOOGLE_CALENDAR_AUTH),
  });
}

export function useCalendarEvents() {
  return useQuery<CalendarEvent[]>({
    queryKey: ["calendar-events"],
    queryFn: () =>
      apiClient.get<CalendarEvent[]>(API_URLS.CALENDAR_EVENTS),
  });
}

export function useDisconnectCalendar() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (connectionId: number) =>
      apiClient.delete(API_URLS.calendarConnectionDetail(connectionId)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["calendar-connections"] });
      queryClient.invalidateQueries({ queryKey: ["calendar-events"] });
    },
  });
}

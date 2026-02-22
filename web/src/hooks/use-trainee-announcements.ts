"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  Announcement,
  AnnouncementUnreadCount,
} from "@/types/trainee-dashboard";

const STALE_TIME = 5 * 60 * 1000; // 5 minutes

export function useAnnouncements() {
  return useQuery<Announcement[]>({
    queryKey: ["trainee-dashboard", "announcements"],
    queryFn: () =>
      apiClient.get<Announcement[]>(API_URLS.TRAINEE_ANNOUNCEMENTS),
    staleTime: STALE_TIME,
  });
}

export function useAnnouncementUnreadCount() {
  return useQuery<AnnouncementUnreadCount>({
    queryKey: ["trainee-dashboard", "announcements-unread"],
    queryFn: () =>
      apiClient.get<AnnouncementUnreadCount>(
        API_URLS.TRAINEE_ANNOUNCEMENTS_UNREAD,
      ),
    staleTime: 30_000, // 30 seconds for unread count
  });
}

export function useMarkAnnouncementsRead() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () =>
      apiClient.post(API_URLS.TRAINEE_ANNOUNCEMENTS_MARK_READ, {}),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["trainee-dashboard", "announcements-unread"],
      });
      queryClient.invalidateQueries({
        queryKey: ["trainee-dashboard", "announcements"],
      });
    },
  });
}

export function useMarkAnnouncementRead() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (announcementId: number) =>
      apiClient.post(API_URLS.traineeAnnouncementMarkRead(announcementId), {}),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["trainee-dashboard", "announcements-unread"],
      });
      queryClient.invalidateQueries({
        queryKey: ["trainee-dashboard", "announcements"],
      });
    },
  });
}

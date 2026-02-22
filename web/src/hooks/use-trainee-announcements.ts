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
    onMutate: async () => {
      await queryClient.cancelQueries({
        queryKey: ["trainee-dashboard", "announcements"],
      });
      await queryClient.cancelQueries({
        queryKey: ["trainee-dashboard", "announcements-unread"],
      });

      const previousAnnouncements = queryClient.getQueryData<Announcement[]>(
        ["trainee-dashboard", "announcements"],
      );
      const previousUnread = queryClient.getQueryData<AnnouncementUnreadCount>(
        ["trainee-dashboard", "announcements-unread"],
      );

      // Optimistically mark all as read
      if (previousAnnouncements) {
        queryClient.setQueryData<Announcement[]>(
          ["trainee-dashboard", "announcements"],
          previousAnnouncements.map((a) => ({ ...a, is_read: true })),
        );
      }
      queryClient.setQueryData<AnnouncementUnreadCount>(
        ["trainee-dashboard", "announcements-unread"],
        { unread_count: 0 },
      );

      return { previousAnnouncements, previousUnread };
    },
    onError: (_err, _vars, context) => {
      if (context?.previousAnnouncements) {
        queryClient.setQueryData(
          ["trainee-dashboard", "announcements"],
          context.previousAnnouncements,
        );
      }
      if (context?.previousUnread) {
        queryClient.setQueryData(
          ["trainee-dashboard", "announcements-unread"],
          context.previousUnread,
        );
      }
    },
    onSettled: () => {
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
    onMutate: async (announcementId: number) => {
      // Cancel outgoing refetches so they don't overwrite our optimistic update
      await queryClient.cancelQueries({
        queryKey: ["trainee-dashboard", "announcements"],
      });
      await queryClient.cancelQueries({
        queryKey: ["trainee-dashboard", "announcements-unread"],
      });

      // Snapshot previous values for rollback
      const previousAnnouncements = queryClient.getQueryData<Announcement[]>(
        ["trainee-dashboard", "announcements"],
      );
      const previousUnread = queryClient.getQueryData<AnnouncementUnreadCount>(
        ["trainee-dashboard", "announcements-unread"],
      );

      // Optimistically mark announcement as read
      if (previousAnnouncements) {
        queryClient.setQueryData<Announcement[]>(
          ["trainee-dashboard", "announcements"],
          previousAnnouncements.map((a) =>
            a.id === announcementId ? { ...a, is_read: true } : a,
          ),
        );
      }

      // Optimistically decrement unread count
      if (previousUnread && previousUnread.unread_count > 0) {
        queryClient.setQueryData<AnnouncementUnreadCount>(
          ["trainee-dashboard", "announcements-unread"],
          { unread_count: previousUnread.unread_count - 1 },
        );
      }

      return { previousAnnouncements, previousUnread };
    },
    onError: (_err, _announcementId, context) => {
      // Rollback on error
      if (context?.previousAnnouncements) {
        queryClient.setQueryData(
          ["trainee-dashboard", "announcements"],
          context.previousAnnouncements,
        );
      }
      if (context?.previousUnread) {
        queryClient.setQueryData(
          ["trainee-dashboard", "announcements-unread"],
          context.previousUnread,
        );
      }
    },
    onSettled: () => {
      // Re-fetch to ensure server state is in sync
      queryClient.invalidateQueries({
        queryKey: ["trainee-dashboard", "announcements-unread"],
      });
      queryClient.invalidateQueries({
        queryKey: ["trainee-dashboard", "announcements"],
      });
    },
  });
}

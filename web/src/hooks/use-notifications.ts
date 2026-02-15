"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { PaginatedResponse } from "@/types/api";
import type { Notification, UnreadCount } from "@/types/notification";

export function useNotifications() {
  return useQuery<PaginatedResponse<Notification>>({
    queryKey: ["notifications"],
    queryFn: () =>
      apiClient.get<PaginatedResponse<Notification>>(API_URLS.NOTIFICATIONS),
  });
}

export function useUnreadCount() {
  return useQuery<UnreadCount>({
    queryKey: ["notifications", "unread-count"],
    queryFn: () =>
      apiClient.get<UnreadCount>(API_URLS.NOTIFICATIONS_UNREAD_COUNT),
    refetchInterval: 30_000,
  });
}

export function useMarkAsRead() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      apiClient.post(API_URLS.notificationRead(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["notifications"] });
    },
  });
}

export function useMarkAllAsRead() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () =>
      apiClient.post(API_URLS.NOTIFICATIONS_MARK_ALL_READ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["notifications"] });
    },
  });
}

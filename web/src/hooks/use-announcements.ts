"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { PaginatedResponse } from "@/types/api";
import type {
  Announcement,
  CreateAnnouncementPayload,
  UpdateAnnouncementPayload,
} from "@/types/announcement";

export function useAnnouncements(page: number = 1) {
  return useQuery<PaginatedResponse<Announcement>>({
    queryKey: ["announcements", page],
    queryFn: () =>
      apiClient.get<PaginatedResponse<Announcement>>(
        `${API_URLS.ANNOUNCEMENTS}?page=${page}`,
      ),
  });
}

export function useCreateAnnouncement() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateAnnouncementPayload) =>
      apiClient.post<Announcement>(API_URLS.ANNOUNCEMENTS, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["announcements"] });
    },
  });
}

export function useUpdateAnnouncement(id: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: UpdateAnnouncementPayload) =>
      apiClient.patch<Announcement>(API_URLS.announcementDetail(id), data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["announcements"] });
    },
  });
}

export function useDeleteAnnouncement() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      apiClient.delete(API_URLS.announcementDetail(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["announcements"] });
    },
  });
}

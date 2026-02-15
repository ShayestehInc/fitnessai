"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { PaginatedResponse } from "@/types/api";
import type { Invitation, CreateInvitationPayload } from "@/types/invitation";

export function useInvitations(page: number = 1) {
  const url = `${API_URLS.INVITATIONS}?page=${page}`;
  return useQuery<PaginatedResponse<Invitation>>({
    queryKey: ["invitations", page],
    queryFn: () =>
      apiClient.get<PaginatedResponse<Invitation>>(url),
  });
}

export function useCreateInvitation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateInvitationPayload) =>
      apiClient.post<Invitation>(API_URLS.INVITATIONS, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["invitations"] });
    },
  });
}

export function useResendInvitation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      apiClient.post<Invitation>(API_URLS.invitationResend(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["invitations"] });
    },
  });
}

export function useCancelInvitation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      apiClient.delete(API_URLS.invitationDetail(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["invitations"] });
    },
  });
}

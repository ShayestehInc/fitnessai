"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { PaginatedResponse } from "@/types/api";
import type { Invitation, CreateInvitationPayload } from "@/types/invitation";

export function useInvitations() {
  return useQuery<PaginatedResponse<Invitation>>({
    queryKey: ["invitations"],
    queryFn: () =>
      apiClient.get<PaginatedResponse<Invitation>>(API_URLS.INVITATIONS),
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

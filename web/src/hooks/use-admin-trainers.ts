"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  AdminTrainerListItem,
  ImpersonationResponse,
  EndImpersonationResponse,
} from "@/types/admin";

interface TrainerFilters {
  search?: string;
  active?: boolean;
}

export function useAdminTrainers(filters: TrainerFilters = {}) {
  const params = new URLSearchParams();
  if (filters.search) params.set("search", filters.search);
  if (filters.active !== undefined) params.set("active", String(filters.active));

  const queryString = params.toString();
  const url = queryString
    ? `${API_URLS.ADMIN_TRAINERS}?${queryString}`
    : API_URLS.ADMIN_TRAINERS;

  return useQuery<AdminTrainerListItem[]>({
    queryKey: ["admin", "trainers", filters],
    queryFn: () => apiClient.get<AdminTrainerListItem[]>(url),
    staleTime: 5 * 60 * 1000,
  });
}

export function useImpersonateTrainer() {
  return useMutation<ImpersonationResponse, Error, number>({
    mutationFn: (trainerId: number) =>
      apiClient.post<ImpersonationResponse>(
        API_URLS.adminImpersonate(trainerId),
      ),
  });
}

export function useEndImpersonation() {
  return useMutation<EndImpersonationResponse, Error>({
    mutationFn: () =>
      apiClient.post<EndImpersonationResponse>(API_URLS.ADMIN_IMPERSONATE_END),
  });
}

export function useActivateDeactivateTrainer() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      userId,
      isActive,
    }: {
      userId: number;
      isActive: boolean;
    }) =>
      apiClient.patch(API_URLS.adminUserDetail(userId), {
        is_active: isActive,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "trainers"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "dashboard"] });
    },
  });
}

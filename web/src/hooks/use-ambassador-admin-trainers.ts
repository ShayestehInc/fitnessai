"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  AmbassadorAdminTrainer,
  CreateTrainerPayload,
  AmbassadorAdminImpersonationResponse,
} from "@/types/ambassador";

interface TrainerFilters {
  search?: string;
}

export function useAmbassadorAdminTrainers(filters: TrainerFilters = {}) {
  const params = new URLSearchParams();
  if (filters.search) params.set("search", filters.search);

  const queryString = params.toString();
  const url = queryString
    ? `${API_URLS.AMBASSADOR_ADMIN_TRAINERS}?${queryString}`
    : API_URLS.AMBASSADOR_ADMIN_TRAINERS;

  return useQuery<AmbassadorAdminTrainer[]>({
    queryKey: ["ambassador-admin", "trainers", filters],
    queryFn: () => apiClient.get<AmbassadorAdminTrainer[]>(url),
    staleTime: 5 * 60 * 1000,
  });
}

export function useAmbassadorAdminTrainerDetail(trainerId: number) {
  return useQuery<AmbassadorAdminTrainer>({
    queryKey: ["ambassador-admin", "trainers", trainerId],
    queryFn: () =>
      apiClient.get<AmbassadorAdminTrainer>(
        API_URLS.ambassadorAdminTrainerDetail(trainerId),
      ),
    enabled: trainerId > 0,
  });
}

export function useAmbassadorAdminCreateTrainer() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateTrainerPayload) =>
      apiClient.post(API_URLS.AMBASSADOR_ADMIN_CREATE_TRAINER, data),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["ambassador-admin", "trainers"],
      });
      queryClient.invalidateQueries({
        queryKey: ["ambassador-admin", "dashboard"],
      });
    },
  });
}

export function useAmbassadorAdminUpdateTrainer() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      trainerId,
      data,
    }: {
      trainerId: number;
      data: Partial<{ first_name: string; last_name: string; is_active: boolean }>;
    }) =>
      apiClient.patch(
        API_URLS.ambassadorAdminTrainerDetail(trainerId),
        data,
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["ambassador-admin", "trainers"],
      });
      queryClient.invalidateQueries({
        queryKey: ["ambassador-admin", "dashboard"],
      });
    },
  });
}

export function useAmbassadorAdminImpersonateTrainer() {
  return useMutation<AmbassadorAdminImpersonationResponse, Error, number>({
    mutationFn: (trainerId: number) =>
      apiClient.post<AmbassadorAdminImpersonationResponse>(
        API_URLS.ambassadorAdminImpersonate(trainerId),
      ),
  });
}

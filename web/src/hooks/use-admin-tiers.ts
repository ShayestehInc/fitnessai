"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  AdminSubscriptionTier,
  CreateTierPayload,
  UpdateTierPayload,
} from "@/types/admin";

export function useAdminTiers() {
  return useQuery<AdminSubscriptionTier[]>({
    queryKey: ["admin", "tiers"],
    queryFn: () =>
      apiClient.get<AdminSubscriptionTier[]>(API_URLS.ADMIN_TIERS),
    staleTime: 5 * 60 * 1000,
  });
}

export function useCreateTier() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateTierPayload) =>
      apiClient.post<AdminSubscriptionTier>(API_URLS.ADMIN_TIERS, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "tiers"] });
    },
  });
}

export function useUpdateTier() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: UpdateTierPayload }) =>
      apiClient.patch<AdminSubscriptionTier>(
        API_URLS.adminTierDetail(id),
        data,
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "tiers"] });
    },
  });
}

export function useDeleteTier() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      apiClient.delete(API_URLS.adminTierDetail(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "tiers"] });
    },
  });
}

export function useToggleTierActive() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      apiClient.post<AdminSubscriptionTier>(
        API_URLS.adminTierToggleActive(id),
      ),
    onMutate: async (id: number) => {
      await queryClient.cancelQueries({ queryKey: ["admin", "tiers"] });
      const previous = queryClient.getQueryData<AdminSubscriptionTier[]>([
        "admin",
        "tiers",
      ]);
      if (previous) {
        queryClient.setQueryData<AdminSubscriptionTier[]>(
          ["admin", "tiers"],
          previous.map((tier) =>
            tier.id === id ? { ...tier, is_active: !tier.is_active } : tier,
          ),
        );
      }
      return { previous };
    },
    onError: (_err, _id, context) => {
      if (context?.previous) {
        queryClient.setQueryData(["admin", "tiers"], context.previous);
      }
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "tiers"] });
    },
  });
}

export function useSeedDefaultTiers() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () =>
      apiClient.post<AdminSubscriptionTier[]>(
        API_URLS.ADMIN_TIERS_SEED_DEFAULTS,
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "tiers"] });
    },
  });
}

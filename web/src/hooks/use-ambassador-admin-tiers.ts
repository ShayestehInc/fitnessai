"use client";

import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { AdminSubscriptionTier } from "@/types/admin";

export function useAmbassadorAdminTiers() {
  return useQuery<AdminSubscriptionTier[]>({
    queryKey: ["ambassador-admin", "tiers"],
    queryFn: () =>
      apiClient.get<AdminSubscriptionTier[]>(API_URLS.AMBASSADOR_ADMIN_TIERS),
    staleTime: 5 * 60 * 1000,
  });
}

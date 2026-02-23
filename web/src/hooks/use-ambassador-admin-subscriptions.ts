"use client";

import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { AdminSubscriptionListItem } from "@/types/admin";

interface SubscriptionFilters {
  status?: string;
  tier?: string;
  search?: string;
}

export function useAmbassadorAdminSubscriptions(
  filters: SubscriptionFilters = {},
) {
  const params = new URLSearchParams();
  if (filters.status) params.set("status", filters.status);
  if (filters.tier) params.set("tier", filters.tier);
  if (filters.search) params.set("search", filters.search);

  const queryString = params.toString();
  const url = queryString
    ? `${API_URLS.AMBASSADOR_ADMIN_SUBSCRIPTIONS}?${queryString}`
    : API_URLS.AMBASSADOR_ADMIN_SUBSCRIPTIONS;

  return useQuery<AdminSubscriptionListItem[]>({
    queryKey: ["ambassador-admin", "subscriptions", filters],
    queryFn: () => apiClient.get<AdminSubscriptionListItem[]>(url),
    staleTime: 5 * 60 * 1000,
  });
}

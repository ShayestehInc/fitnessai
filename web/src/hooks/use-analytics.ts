"use client";

import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  AdherenceAnalytics,
  AdherencePeriod,
  AdherenceTrends,
  ProgressAnalytics,
} from "@/types/analytics";

export function useAdherenceAnalytics(days: AdherencePeriod) {
  return useQuery<AdherenceAnalytics>({
    queryKey: ["analytics", "adherence", days],
    queryFn: () =>
      apiClient.get<AdherenceAnalytics>(
        `${API_URLS.ANALYTICS_ADHERENCE}?days=${days}`,
      ),
    staleTime: 5 * 60 * 1000,
  });
}

export function useAdherenceTrends(days: AdherencePeriod) {
  return useQuery<AdherenceTrends>({
    queryKey: ["analytics", "adherence-trends", days],
    queryFn: () =>
      apiClient.get<AdherenceTrends>(
        `${API_URLS.ANALYTICS_ADHERENCE_TRENDS}?days=${days}`,
      ),
    staleTime: 5 * 60 * 1000,
  });
}

export function useProgressAnalytics() {
  return useQuery<ProgressAnalytics>({
    queryKey: ["analytics", "progress"],
    queryFn: () =>
      apiClient.get<ProgressAnalytics>(API_URLS.ANALYTICS_PROGRESS),
    staleTime: 5 * 60 * 1000,
  });
}

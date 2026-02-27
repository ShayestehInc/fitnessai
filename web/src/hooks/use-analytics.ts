"use client";

import { useQuery, keepPreviousData } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  AdherenceAnalytics,
  AdherencePeriod,
  AdherenceTrends,
  ProgressAnalytics,
  RevenueAnalytics,
  RevenuePeriod,
} from "@/types/analytics";
import type {
  RetentionAnalytics,
  RetentionPeriod,
  AtRiskResponse,
} from "@/types/retention";

export function useAdherenceAnalytics(days: AdherencePeriod) {
  return useQuery<AdherenceAnalytics>({
    queryKey: ["analytics", "adherence", days],
    queryFn: () =>
      apiClient.get<AdherenceAnalytics>(
        `${API_URLS.ANALYTICS_ADHERENCE}?days=${days}`,
      ),
    staleTime: 5 * 60 * 1000,
    placeholderData: keepPreviousData,
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
    placeholderData: keepPreviousData,
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

export function useRevenueAnalytics(days: RevenuePeriod) {
  return useQuery<RevenueAnalytics>({
    queryKey: ["analytics", "revenue", days],
    queryFn: () =>
      apiClient.get<RevenueAnalytics>(
        `${API_URLS.ANALYTICS_REVENUE}?days=${days}`,
      ),
    staleTime: 5 * 60 * 1000,
    // Keep previous results visible while a new period is loading.
    // Prevents jarring flash-to-skeleton when switching 30d / 90d / 1y.
    placeholderData: keepPreviousData,
  });
}

export function useRetentionAnalytics(days: RetentionPeriod) {
  return useQuery<RetentionAnalytics>({
    queryKey: ["analytics", "retention", days],
    queryFn: () =>
      apiClient.get<RetentionAnalytics>(
        `${API_URLS.ANALYTICS_RETENTION}?days=${days}`,
      ),
    staleTime: 5 * 60 * 1000,
    placeholderData: keepPreviousData,
  });
}

export function useAtRiskTrainees(days: RetentionPeriod) {
  return useQuery<AtRiskResponse>({
    queryKey: ["analytics", "at-risk", days],
    queryFn: () =>
      apiClient.get<AtRiskResponse>(
        `${API_URLS.ANALYTICS_AT_RISK}?days=${days}`,
      ),
    staleTime: 5 * 60 * 1000,
    placeholderData: keepPreviousData,
  });
}

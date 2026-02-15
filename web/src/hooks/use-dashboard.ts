"use client";

import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { DashboardStats, DashboardOverview } from "@/types/trainer";

export function useDashboardStats() {
  return useQuery<DashboardStats>({
    queryKey: ["dashboard", "stats"],
    queryFn: () => apiClient.get<DashboardStats>(API_URLS.DASHBOARD_STATS),
  });
}

export function useDashboardOverview() {
  return useQuery<DashboardOverview>({
    queryKey: ["dashboard", "overview"],
    queryFn: () =>
      apiClient.get<DashboardOverview>(API_URLS.DASHBOARD_OVERVIEW),
  });
}

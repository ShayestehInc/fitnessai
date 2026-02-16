"use client";

import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { AdminDashboardStats } from "@/types/admin";

export function useAdminDashboard() {
  return useQuery<AdminDashboardStats>({
    queryKey: ["admin", "dashboard"],
    queryFn: () =>
      apiClient.get<AdminDashboardStats>(API_URLS.ADMIN_DASHBOARD),
    staleTime: 5 * 60 * 1000,
  });
}

"use client";

import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { AmbassadorAdminDashboardData } from "@/types/ambassador";

export function useAmbassadorAdminDashboard() {
  return useQuery<AmbassadorAdminDashboardData>({
    queryKey: ["ambassador-admin", "dashboard"],
    queryFn: () =>
      apiClient.get<AmbassadorAdminDashboardData>(
        API_URLS.AMBASSADOR_ADMIN_DASHBOARD,
      ),
    staleTime: 5 * 60 * 1000,
  });
}

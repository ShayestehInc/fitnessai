"use client";

import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { Achievement } from "@/types/trainee-dashboard";

const STALE_TIME = 5 * 60 * 1000; // 5 minutes

export function useAchievements() {
  return useQuery<Achievement[]>({
    queryKey: ["trainee-dashboard", "achievements"],
    queryFn: () =>
      apiClient.get<Achievement[]>(API_URLS.TRAINEE_ACHIEVEMENTS),
    staleTime: STALE_TIME,
  });
}

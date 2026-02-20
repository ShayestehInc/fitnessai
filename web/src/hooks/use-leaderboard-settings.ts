"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";

export interface LeaderboardSetting {
  metric_type: string;
  time_period: string;
  is_enabled: boolean;
}

export function useLeaderboardSettings() {
  return useQuery<LeaderboardSetting[]>({
    queryKey: ["leaderboard-settings"],
    queryFn: () =>
      apiClient.get<LeaderboardSetting[]>(API_URLS.LEADERBOARD_SETTINGS),
  });
}

export function useUpdateLeaderboardSetting() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: {
      metric_type: string;
      time_period: string;
      is_enabled: boolean;
    }) => apiClient.post(API_URLS.LEADERBOARD_SETTINGS, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["leaderboard-settings"] });
    },
  });
}

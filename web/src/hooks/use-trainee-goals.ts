"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";

interface UpdateTraineeGoalsPayload {
  calories_goal: number;
  protein_goal: number;
  carbs_goal: number;
  fat_goal: number;
  weight_target?: number;
}

export function useUpdateTraineeGoals(traineeId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: UpdateTraineeGoalsPayload) =>
      apiClient.patch(API_URLS.traineeGoals(traineeId), data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["trainee", traineeId] });
    },
  });
}

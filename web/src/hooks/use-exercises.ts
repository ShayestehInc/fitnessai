"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { PaginatedResponse } from "@/types/api";
import type { Exercise, MuscleGroup, DifficultyLevel } from "@/types/program";

export function useExercises(
  search: string = "",
  muscleGroup: MuscleGroup | "" = "",
  page: number = 1,
  difficultyLevel: DifficultyLevel | "" = "",
) {
  const params = new URLSearchParams();
  if (search) params.set("search", search);
  if (muscleGroup) params.set("muscle_group", muscleGroup);
  if (difficultyLevel) params.set("difficulty_level", difficultyLevel);
  params.set("page", String(page));
  params.set("page_size", "100");

  const queryString = params.toString();

  return useQuery<PaginatedResponse<Exercise>>({
    queryKey: ["exercises", search, muscleGroup, page, difficultyLevel],
    queryFn: () =>
      apiClient.get<PaginatedResponse<Exercise>>(
        `${API_URLS.EXERCISES}?${queryString}`,
      ),
    staleTime: 5 * 60 * 1000,
  });
}

interface CreateExercisePayload {
  name: string;
  muscle_group: string;
  description?: string;
  video_url?: string;
  image_url?: string;
}

export function useCreateExercise() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateExercisePayload) =>
      apiClient.post<Exercise>(API_URLS.EXERCISES, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["exercises"] });
    },
  });
}

export function useUpdateExercise(id: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: Partial<CreateExercisePayload>) =>
      apiClient.patch<Exercise>(`${API_URLS.EXERCISES}${id}/`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["exercises"] });
    },
  });
}

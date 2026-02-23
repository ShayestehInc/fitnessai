"use client";

import {
  useInfiniteQuery,
  useMutation,
  useQueryClient,
} from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { PaginatedResponse } from "@/types/api";
import type { Exercise, MuscleGroup, DifficultyLevel } from "@/types/program";

const PAGE_SIZE = 60;

export function useExercises(
  search: string = "",
  muscleGroup: MuscleGroup | "" = "",
  difficultyLevel: DifficultyLevel | "" = "",
) {
  return useInfiniteQuery<PaginatedResponse<Exercise>>({
    queryKey: ["exercises", search, muscleGroup, difficultyLevel],
    queryFn: ({ pageParam }) => {
      const params = new URLSearchParams();
      if (search) params.set("search", search);
      if (muscleGroup) params.set("muscle_group", muscleGroup);
      if (difficultyLevel) params.set("difficulty_level", difficultyLevel);
      params.set("page", String(pageParam));
      params.set("page_size", String(PAGE_SIZE));
      return apiClient.get<PaginatedResponse<Exercise>>(
        `${API_URLS.EXERCISES}?${params.toString()}`,
      );
    },
    initialPageParam: 1,
    getNextPageParam: (lastPage, _allPages, lastPageParam) =>
      lastPage.next ? (lastPageParam as number) + 1 : undefined,
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

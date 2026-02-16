"use client";

import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { PaginatedResponse } from "@/types/api";
import type { Exercise, MuscleGroup } from "@/types/program";

export function useExercises(
  search: string = "",
  muscleGroup: MuscleGroup | "" = "",
) {
  const params = new URLSearchParams();
  if (search) params.set("search", search);
  if (muscleGroup) params.set("muscle_group", muscleGroup);
  params.set("page_size", "100");

  const queryString = params.toString();

  return useQuery<PaginatedResponse<Exercise>>({
    queryKey: ["exercises", search, muscleGroup],
    queryFn: () =>
      apiClient.get<PaginatedResponse<Exercise>>(
        `${API_URLS.EXERCISES}?${queryString}`,
      ),
    staleTime: 5 * 60 * 1000,
  });
}

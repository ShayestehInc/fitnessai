"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { PaginatedResponse } from "@/types/api";
import type {
  ProgramTemplate,
  CreateProgramPayload,
  UpdateProgramPayload,
  AssignProgramPayload,
} from "@/types/program";
import type { TraineeListItem } from "@/types/trainer";

export function usePrograms(page: number = 1, search: string = "") {
  const params = new URLSearchParams();
  params.set("page", String(page));
  if (search) params.set("search", search);

  return useQuery<PaginatedResponse<ProgramTemplate>>({
    queryKey: ["programs", page, search],
    queryFn: () =>
      apiClient.get<PaginatedResponse<ProgramTemplate>>(
        `${API_URLS.PROGRAM_TEMPLATES}?${params.toString()}`,
      ),
  });
}

export function useProgram(id: number) {
  return useQuery<ProgramTemplate>({
    queryKey: ["program", id],
    queryFn: () =>
      apiClient.get<ProgramTemplate>(API_URLS.programTemplateDetail(id)),
    enabled: id > 0,
  });
}

export function useCreateProgram() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateProgramPayload) =>
      apiClient.post<ProgramTemplate>(API_URLS.PROGRAM_TEMPLATES, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["programs"] });
    },
  });
}

export function useUpdateProgram(id: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: UpdateProgramPayload) =>
      apiClient.patch<ProgramTemplate>(
        API_URLS.programTemplateDetail(id),
        data,
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["programs"] });
      queryClient.invalidateQueries({ queryKey: ["program", id] });
    },
  });
}

export function useDeleteProgram() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      apiClient.delete(API_URLS.programTemplateDetail(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["programs"] });
    },
  });
}

export function useAllTrainees() {
  return useQuery<TraineeListItem[]>({
    queryKey: ["trainees", "all"],
    queryFn: async () => {
      const response = await apiClient.get<PaginatedResponse<TraineeListItem>>(
        `${API_URLS.TRAINEES}?page_size=200`,
      );
      return response.results;
    },
    staleTime: 5 * 60 * 1000,
  });
}

export function useAssignProgram(templateId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: AssignProgramPayload) =>
      apiClient.post(API_URLS.programTemplateAssign(templateId), data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["programs"] });
      queryClient.invalidateQueries({ queryKey: ["trainees"] });
    },
  });
}

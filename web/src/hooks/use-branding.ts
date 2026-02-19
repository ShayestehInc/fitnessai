"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { TrainerBranding, UpdateBrandingPayload } from "@/types/branding";

export function useBranding() {
  return useQuery<TrainerBranding>({
    queryKey: ["branding"],
    queryFn: () => apiClient.get<TrainerBranding>(API_URLS.TRAINER_BRANDING),
  });
}

export function useUpdateBranding() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: UpdateBrandingPayload) =>
      apiClient.patch<TrainerBranding>(API_URLS.TRAINER_BRANDING, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["branding"] });
    },
  });
}

export function useUploadLogo() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (file: File) => {
      const formData = new FormData();
      formData.append("logo", file);
      return apiClient.postFormData<TrainerBranding>(
        API_URLS.TRAINER_BRANDING_LOGO,
        formData,
      );
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["branding"] });
    },
  });
}

export function useRemoveLogo() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () =>
      apiClient.delete(API_URLS.TRAINER_BRANDING_LOGO),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["branding"] });
    },
  });
}

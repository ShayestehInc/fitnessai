"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient, ApiError } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { User } from "@/types/user";

interface UpdateProfilePayload {
  first_name: string;
  last_name: string;
  business_name: string;
}

interface UpdateProfileResponse {
  success: boolean;
  user: User;
}

interface ChangePasswordPayload {
  current_password: string;
  new_password: string;
}

interface ProfileImageResponse {
  success: boolean;
  profile_image: string | null;
  user: User;
}

export function useUpdateProfile() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: UpdateProfilePayload) =>
      apiClient.patch<UpdateProfileResponse>(API_URLS.UPDATE_PROFILE, data),
    onSuccess: (response) => {
      queryClient.setQueryData(["current-user"], response.user);
    },
  });
}

export function useUploadProfileImage() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (file: File) => {
      const formData = new FormData();
      formData.append("image", file);
      return apiClient.postFormData<ProfileImageResponse>(
        API_URLS.PROFILE_IMAGE,
        formData,
      );
    },
    onSuccess: (response) => {
      queryClient.setQueryData(["current-user"], response.user);
    },
  });
}

export function useDeleteProfileImage() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () =>
      apiClient.delete<{ success: boolean; user: User }>(
        API_URLS.PROFILE_IMAGE,
      ),
    onSuccess: (response) => {
      queryClient.setQueryData(["current-user"], response.user);
    },
  });
}

export function useChangePassword() {
  return useMutation<void, ApiError, ChangePasswordPayload>({
    mutationFn: (data) =>
      apiClient.post(API_URLS.CHANGE_PASSWORD, data),
  });
}

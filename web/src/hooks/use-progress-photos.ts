"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  ProgressPhoto,
  ProgressPhotoPage,
  PhotoCategory,
} from "@/types/progress";

interface UseProgressPhotosParams {
  category?: PhotoCategory;
  traineeId?: number;
  page?: number;
}

export function useProgressPhotos({
  category,
  traineeId,
  page = 1,
}: UseProgressPhotosParams = {}) {
  const params = new URLSearchParams();
  if (category && category !== "all") params.set("category", category);
  if (traineeId) params.set("trainee_id", String(traineeId));
  if (page > 1) params.set("page", String(page));

  const queryString = params.toString();
  const url = queryString
    ? `${API_URLS.PROGRESS_PHOTOS}?${queryString}`
    : API_URLS.PROGRESS_PHOTOS;

  return useQuery<ProgressPhotoPage>({
    queryKey: ["progress-photos", category ?? "all", traineeId ?? "self", page],
    queryFn: () => apiClient.get<ProgressPhotoPage>(url),
    staleTime: 2 * 60 * 1000,
  });
}

export function useUploadProgressPhoto() {
  const queryClient = useQueryClient();

  return useMutation<ProgressPhoto, Error, FormData>({
    mutationFn: (formData: FormData) =>
      apiClient.postFormData<ProgressPhoto>(
        API_URLS.PROGRESS_PHOTOS,
        formData,
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["progress-photos"] });
    },
  });
}

export function useDeleteProgressPhoto() {
  const queryClient = useQueryClient();

  return useMutation<void, Error, number>({
    mutationFn: (id: number) =>
      apiClient.delete(API_URLS.progressPhotoDetail(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["progress-photos"] });
    },
  });
}

export function useComparePhotos(photo1Id: number, photo2Id: number) {
  const params = new URLSearchParams({
    photo1: String(photo1Id),
    photo2: String(photo2Id),
  });

  return useQuery<{ photos: ProgressPhoto[] }>({
    queryKey: ["progress-photos", "compare", photo1Id, photo2Id],
    queryFn: () =>
      apiClient.get(`${API_URLS.progressPhotoCompare}?${params.toString()}`),
    enabled: photo1Id > 0 && photo2Id > 0,
  });
}

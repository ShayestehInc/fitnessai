"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { PaginatedResponse } from "@/types/api";
import type {
  FeatureRequest,
  FeatureRequestDetail,
  FeatureComment,
  CreateFeatureRequestPayload,
  FeatureRequestStatus,
  FeatureRequestCategory,
} from "@/types/feature-request";

export function useFeatureRequests(
  sort: string = "votes",
  status: FeatureRequestStatus | "" = "",
  page: number = 1,
  category: FeatureRequestCategory | "" = "",
) {
  const params = new URLSearchParams();
  params.set("page", String(page));
  if (sort) params.set("ordering", sort === "votes" ? "-vote_count" : "-created_at");
  if (status) params.set("status", status);
  if (category) params.set("category", category);

  return useQuery<PaginatedResponse<FeatureRequest>>({
    queryKey: ["feature-requests", sort, status, category, page],
    queryFn: () =>
      apiClient.get<PaginatedResponse<FeatureRequest>>(
        `${API_URLS.FEATURE_REQUESTS}?${params.toString()}`,
      ),
  });
}

export function useFeatureRequest(id: number) {
  return useQuery<FeatureRequestDetail>({
    queryKey: ["feature-request", id],
    queryFn: () =>
      apiClient.get<FeatureRequestDetail>(API_URLS.featureRequestDetail(id)),
    enabled: id > 0,
  });
}

export function useCreateFeatureRequest() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateFeatureRequestPayload) =>
      apiClient.post<FeatureRequest>(API_URLS.FEATURE_REQUESTS, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["feature-requests"] });
    },
  });
}

interface VoteInput {
  id: number;
  vote_type: "up" | "down" | "remove";
}

export function useVoteFeatureRequest() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, vote_type }: VoteInput) =>
      apiClient.post(API_URLS.featureRequestVote(id), { vote_type }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["feature-requests"] });
      queryClient.invalidateQueries({ queryKey: ["feature-request"] });
    },
  });
}

export function useFeatureComments(id: number, page: number = 1) {
  return useQuery<PaginatedResponse<FeatureComment>>({
    queryKey: ["feature-comments", id, page],
    queryFn: () =>
      apiClient.get<PaginatedResponse<FeatureComment>>(
        `${API_URLS.featureRequestComments(id)}?page=${page}`,
      ),
    enabled: id > 0,
  });
}

export function useCreateFeatureComment(id: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (content: string) =>
      apiClient.post<FeatureComment>(API_URLS.featureRequestComments(id), {
        content,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["feature-comments", id] });
      queryClient.invalidateQueries({ queryKey: ["feature-requests"] });
      queryClient.invalidateQueries({ queryKey: ["feature-request", id] });
    },
  });
}

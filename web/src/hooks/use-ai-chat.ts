"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  AiChatThread,
  AiChatThreadDetail,
  AiProvidersResponse,
  CreateThreadRequest,
  SendAiMessageResponse,
} from "@/types/ai-chat";

const THREAD_LIST_KEY = ["ai-threads"] as const;
const threadDetailKey = (id: number) => ["ai-thread", id] as const;

export function useAiThreads() {
  return useQuery<AiChatThread[]>({
    queryKey: THREAD_LIST_KEY,
    queryFn: () => apiClient.get<AiChatThread[]>(API_URLS.AI_THREADS),
  });
}

export function useAiThread(id: number | null) {
  return useQuery<AiChatThreadDetail>({
    queryKey: threadDetailKey(id!),
    queryFn: () =>
      apiClient.get<AiChatThreadDetail>(API_URLS.aiThreadDetail(id!)),
    enabled: id !== null,
  });
}

export function useCreateAiThread() {
  const queryClient = useQueryClient();

  return useMutation<AiChatThread, Error, CreateThreadRequest>({
    mutationFn: (data) =>
      apiClient.post<AiChatThread>(API_URLS.AI_THREADS, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: THREAD_LIST_KEY });
    },
  });
}

export function useSendAiMessage(threadId: number | null) {
  const queryClient = useQueryClient();

  return useMutation<
    SendAiMessageResponse,
    Error,
    { message: string; trainee_id?: number }
  >({
    mutationFn: (data) =>
      apiClient.post<SendAiMessageResponse>(
        API_URLS.aiThreadSend(threadId!),
        data,
      ),
    onSuccess: (data) => {
      // Append new messages to the cached thread detail
      if (threadId !== null) {
        queryClient.setQueryData<AiChatThreadDetail>(
          threadDetailKey(threadId),
          (old) => {
            if (!old) return old;
            return {
              ...old,
              title: data.thread_title,
              last_message_at: data.assistant_message.created_at,
              messages: [
                ...old.messages,
                data.user_message,
                data.assistant_message,
              ],
            };
          },
        );
      }
      // Refresh sidebar list (title, last_message_at may have changed)
      queryClient.invalidateQueries({ queryKey: THREAD_LIST_KEY });
    },
  });
}

export function useRenameAiThread() {
  const queryClient = useQueryClient();

  return useMutation<
    { id: number; title: string },
    Error,
    { threadId: number; title: string }
  >({
    mutationFn: ({ threadId, title }) =>
      apiClient.patch<{ id: number; title: string }>(
        API_URLS.aiThreadDetail(threadId),
        { title },
      ),
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: THREAD_LIST_KEY });
      queryClient.invalidateQueries({ queryKey: threadDetailKey(data.id) });
    },
  });
}

export function useDeleteAiThread() {
  const queryClient = useQueryClient();

  return useMutation<void, Error, number>({
    mutationFn: (threadId) =>
      apiClient.delete<void>(API_URLS.aiThreadDetail(threadId)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: THREAD_LIST_KEY });
    },
  });
}

export function useAiProviders() {
  return useQuery<AiProvidersResponse>({
    queryKey: ["ai-providers"],
    queryFn: () => apiClient.get<AiProvidersResponse>(API_URLS.AI_PROVIDERS),
    staleTime: 10 * 60 * 1000,
  });
}

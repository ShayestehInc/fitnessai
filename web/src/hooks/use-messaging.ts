"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  Conversation,
  ConversationsResponse,
  MessagesResponse,
  Message,
  StartConversationResponse,
  UnreadMessageCount,
} from "@/types/messaging";

export function useConversations() {
  return useQuery<Conversation[]>({
    queryKey: ["messaging", "conversations"],
    queryFn: async () => {
      const response = await apiClient.get<ConversationsResponse>(
        API_URLS.MESSAGING_CONVERSATIONS,
      );
      // Backend now returns paginated response; extract results array
      return response.results;
    },
    refetchInterval: 15_000,
    refetchIntervalInBackground: false,
  });
}

export function useMessages(conversationId: number, page: number = 1) {
  const params = new URLSearchParams({ page: String(page) });
  const url = `${API_URLS.messagingMessages(conversationId)}?${params.toString()}`;
  return useQuery<MessagesResponse>({
    queryKey: ["messaging", "messages", conversationId, page],
    queryFn: () => apiClient.get<MessagesResponse>(url),
    enabled: conversationId > 0,
  });
}

interface SendMessageInput {
  content: string;
  image?: File;
}

export function useSendMessage(conversationId: number) {
  const queryClient = useQueryClient();

  return useMutation<Message, Error, SendMessageInput>({
    mutationFn: ({ content, image }: SendMessageInput) => {
      if (image) {
        const formData = new FormData();
        if (content) formData.append("content", content);
        formData.append("image", image);
        return apiClient.postFormData<Message>(
          API_URLS.messagingSend(conversationId),
          formData,
        );
      }
      return apiClient.post<Message>(API_URLS.messagingSend(conversationId), {
        content,
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["messaging", "messages", conversationId],
      });
      queryClient.invalidateQueries({
        queryKey: ["messaging", "conversations"],
      });
      queryClient.invalidateQueries({
        queryKey: ["messaging", "unread-count"],
      });
    },
  });
}

interface StartConversationInput {
  trainee_id: number;
  content: string;
  image?: File;
}

export function useStartConversation() {
  const queryClient = useQueryClient();

  return useMutation<StartConversationResponse, Error, StartConversationInput>({
    mutationFn: ({ trainee_id, content, image }: StartConversationInput) => {
      if (image) {
        const formData = new FormData();
        formData.append("trainee_id", String(trainee_id));
        if (content) formData.append("content", content);
        formData.append("image", image);
        return apiClient.postFormData<StartConversationResponse>(
          API_URLS.MESSAGING_START_CONVERSATION,
          formData,
        );
      }
      return apiClient.post<StartConversationResponse>(
        API_URLS.MESSAGING_START_CONVERSATION,
        { trainee_id, content },
      );
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["messaging", "conversations"],
      });
      queryClient.invalidateQueries({
        queryKey: ["messaging", "unread-count"],
      });
    },
  });
}

export function useMarkConversationRead(conversationId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () =>
      apiClient.post(API_URLS.messagingMarkRead(conversationId)),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["messaging", "conversations"],
      });
      queryClient.invalidateQueries({
        queryKey: ["messaging", "unread-count"],
      });
    },
  });
}

export function useMessagingUnreadCount() {
  return useQuery<UnreadMessageCount>({
    queryKey: ["messaging", "unread-count"],
    queryFn: () =>
      apiClient.get<UnreadMessageCount>(API_URLS.MESSAGING_UNREAD_COUNT),
    refetchInterval: 30_000,
    refetchIntervalInBackground: false,
  });
}

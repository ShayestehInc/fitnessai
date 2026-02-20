"use client";

import {
  useQuery,
  useMutation,
  useQueryClient,
  keepPreviousData,
} from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  Conversation,
  ConversationsResponse,
  MessagesResponse,
  Message,
  SearchMessagesResponse,
  StartConversationResponse,
  UnreadMessageCount,
} from "@/types/messaging";

export function useConversations(refetchIntervalMs: number = 15_000) {
  return useQuery<Conversation[]>({
    queryKey: ["messaging", "conversations"],
    queryFn: async () => {
      const response = await apiClient.get<ConversationsResponse>(
        API_URLS.MESSAGING_CONVERSATIONS,
      );
      // Backend now returns paginated response; extract results array
      return response.results;
    },
    refetchInterval: refetchIntervalMs,
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

export function useMessagingUnreadCount(refetchIntervalMs: number = 30_000) {
  return useQuery<UnreadMessageCount>({
    queryKey: ["messaging", "unread-count"],
    queryFn: () =>
      apiClient.get<UnreadMessageCount>(API_URLS.MESSAGING_UNREAD_COUNT),
    refetchInterval: refetchIntervalMs,
    refetchIntervalInBackground: false,
  });
}

interface EditMessageInput {
  messageId: number;
  content: string;
}

/**
 * Mutation hook for editing a message's content.
 * Invalidates the messages and conversations caches on success.
 */
export function useEditMessage(conversationId: number) {
  const queryClient = useQueryClient();

  return useMutation<Message, Error, EditMessageInput>({
    mutationFn: ({ messageId, content }: EditMessageInput) =>
      apiClient.patch<Message>(
        API_URLS.messagingEditMessage(conversationId, messageId),
        { content },
      ),
    onSuccess: (updatedMessage, { messageId }) => {
      // Update all cached pages for this conversation
      queryClient.setQueriesData(
        { queryKey: ["messaging", "messages", conversationId] },
        (old: { count: number; next: string | null; previous: string | null; results: Message[] } | undefined) => {
          if (!old) return old;
          return {
            ...old,
            results: old.results.map((m) =>
              m.id === messageId ? updatedMessage : m,
            ),
          };
        },
      );
      queryClient.invalidateQueries({
        queryKey: ["messaging", "conversations"],
      });
    },
  });
}

interface DeleteMessageInput {
  messageId: number;
}

/**
 * Mutation hook for soft-deleting a message.
 * Invalidates the messages and conversations caches on success.
 */
export function useDeleteMessage(conversationId: number) {
  const queryClient = useQueryClient();

  return useMutation<void, Error, DeleteMessageInput>({
    mutationFn: ({ messageId }: DeleteMessageInput) =>
      apiClient.delete(
        API_URLS.messagingDeleteMessage(conversationId, messageId),
      ),
    onSuccess: (_, { messageId }) => {
      // Update all cached pages: mark the message as deleted
      queryClient.setQueriesData(
        { queryKey: ["messaging", "messages", conversationId] },
        (old: { count: number; next: string | null; previous: string | null; results: Message[] } | undefined) => {
          if (!old) return old;
          return {
            ...old,
            results: old.results.map((m) =>
              m.id === messageId
                ? { ...m, content: "", image: null, is_deleted: true }
                : m,
            ),
          };
        },
      );
      queryClient.invalidateQueries({
        queryKey: ["messaging", "conversations"],
      });
    },
  });
}

/**
 * Query hook for searching messages across all conversations.
 * Disabled when query is empty or < 2 characters.
 */
export function useSearchMessages(query: string, page: number = 1) {
  const params = new URLSearchParams();
  if (query) params.set("q", query);
  params.set("page", String(page));

  return useQuery<SearchMessagesResponse>({
    queryKey: ["messaging", "search", query, page],
    queryFn: () =>
      apiClient.get<SearchMessagesResponse>(
        `${API_URLS.MESSAGING_SEARCH}?${params.toString()}`,
      ),
    enabled: query.length >= 2,
    // Keep previous results visible while a new query is loading.
    // Prevents jarring flash-to-skeleton on every keystroke.
    placeholderData: keepPreviousData,
  });
}
